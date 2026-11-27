"""Stage2 auth integration tests against local SQL Server + localhost:5290.
Uses generated TEST accounts; cleanup is restricted to the exact run tag.
"""
import concurrent.futures,json,pathlib,subprocess,threading,urllib.request,urllib.error,uuid
ROOT=pathlib.Path(__file__).resolve().parents[1]
BASE='http://localhost:5290/api'
passed=0

def check(value,label):
 global passed
 assert value,label
 passed+=1;print('PASS '+label,flush=True)

def req(method,path,body=None,token=None,expected=200):
 headers={'Content-Type':'application/json'}
 if token:headers['Authorization']='Bearer '+token
 request=urllib.request.Request(BASE+path,data=None if body is None else json.dumps(body).encode(),headers=headers,method=method)
 try:
  with urllib.request.urlopen(request,timeout=30) as r:status,data=r.status,r.read()
 except urllib.error.HTTPError as e:status,data=e.code,e.read()
 value=json.loads(data) if data else None
 if expected is not None:assert status==expected,(method,path,status,value)
 return status,value

def login(email,password):return req('POST','/auth/login',{'email':email,'password':password})[1]

def cleanup(tag):
 subprocess.run(['powershell','-NoProfile','-File',str(ROOT/'tests/database_checks.ps1'),'-Mode','Cleanup','-RunTag',tag],check=True,capture_output=True)

def run():
 tag=uuid.uuid4().hex[:10];print('Test run '+tag,flush=True)
 config=json.loads((ROOT/'WebApi/appsettings.json').read_text(encoding='utf-8-sig'))
 admin=login(config['Seed']['AdminEmail'],config['Seed']['AdminPassword']);at=admin['token']
 check(admin['member']['role']=='Admin','seed Admin login')
 emails=[f'test-{tag}-{i}@example.com' for i in range(2)];password='Password-'+tag
 try:
  people=[]
  for email in emails:
   _,m=req('POST','/auth/register',{'email':email,'password':password,'givenName':'Test','surname':tag,'roleId':2,'isLocked':False},expected=201)
   check(m['role']=='Member' and m['roleId']==1,'registration always assigns Member')
   check('password' not in json.dumps(m).lower(),'member response excludes password/hash')
   people.append(m)
  req('POST','/auth/register',{'email':emails[0].upper(),'password':password,'givenName':'Duplicate'},expected=409)
  check(True,'email uniqueness is normalized')
  req('POST','/auth/register',{'email':'invalid','password':'short','givenName':''},expected=400)
  req('POST','/auth/register',{'email':f'bad-{tag}@example.com','password':'😀'*30,'givenName':'Too long'},expected=400)
  check(True,'registration validation and bcrypt byte limit')
  req('POST','/auth/login',{'email':emails[0],'password':'incorrect'},expected=401)
  user=login(emails[0].upper(),password);token=user['token']
  _,me=req('GET','/auth/me',token=token)
  check(me['id']==people[0]['id'],'JWT member identity')
  req('GET','/admin/member',token=token,expected=403)
  req('GET','/admin/role',token=token,expected=403)
  req('GET','/member/me',expected=401)
  check(True,'anonymous and Member cannot access admin APIs')
  _,roles=req('GET','/admin/role',token=at)
  check([r['name'] for r in roles]==['Member','Admin'],'admin role list')
  _,listing=req('GET',f'/admin/member?search={tag}&pageSize=1',token=at)
  check(listing['totalItems']==2 and listing['totalPages']==2 and len(listing['items'])==1,'member search and pagination')
  req('GET','/admin/member?pageIndex=0',token=at,expected=400)
  check(True,'invalid pagination rejected')
  _,updated=req('PUT','/member/me',{'givenName':'Updated','surname':tag,'phone':'0900000000','rowVersion':me['rowVersion'],'roleId':2},token)
  check(updated['givenName']=='Updated' and updated['role']=='Member','profile update cannot assign a role')
  req('PUT','/member/me',{'givenName':'Stale','surname':tag,'phone':'','rowVersion':me['rowVersion']},token,409)
  check(True,'stale rowversion rejects lost profile update')
  _,rotated=req('POST','/auth/refresh',{'refreshToken':user['refreshToken']})
  check(rotated['refreshToken']!=user['refreshToken'],'refresh token rotates')
  req('POST','/auth/refresh',{'refreshToken':user['refreshToken']},expected=401)
  check(True,'used refresh token cannot be replayed')
  gate=threading.Barrier(2)
  def refresh(_):
   gate.wait();return req('POST','/auth/refresh',{'refreshToken':rotated['refreshToken']},expected=None)
  with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:results=list(pool.map(refresh,range(2)))
  check(sorted(r[0] for r in results)==[200,401],'concurrent refresh accepts exactly one request')
  rotated=next(r[1] for r in results if r[0]==200)
  device2=login(emails[0],password)
  req('POST','/auth/logout',token=rotated['token'],expected=204)
  req('GET','/member/me',token=rotated['token'],expected=401)
  req('POST','/auth/refresh',{'refreshToken':rotated['refreshToken']},expected=401)
  req('GET','/member/me',token=device2['token'])
  check(True,'logout revokes current session and preserves other device')
  req('PUT','/auth/password',{'currentPassword':'wrong','newPassword':'New-'+password},device2['token'],400)
  req('GET','/member/me',token=device2['token'])
  check(True,'wrong current password does not revoke session')
  device3=login(emails[0],password)
  req('PUT','/auth/password',{'currentPassword':password,'newPassword':'New-'+password},device2['token'],204)
  req('GET','/member/me',token=device2['token'],expected=401)
  req('GET','/member/me',token=device3['token'],expected=401)
  req('POST','/auth/refresh',{'refreshToken':device3['refreshToken']},expected=401)
  req('POST','/auth/login',{'email':emails[0],'password':password},expected=401)
  user=login(emails[0],'New-'+password)
  check(True,'password change revokes all sessions and invalidates old password')
  _,target=req('GET',f"/admin/member/{people[0]['id']}",token=at)
  _,locked=req('PUT',f"/admin/member/{target['id']}/lock",{'isLocked':True,'rowVersion':target['rowVersion']},at)
  req('GET','/member/me',token=user['token'],expected=401)
  req('POST','/auth/login',{'email':emails[0],'password':'New-'+password},expected=403)
  req('POST','/auth/refresh',{'refreshToken':user['refreshToken']},expected=401)
  check(locked['isLocked'],'locking account revokes JWT/refresh and prevents login')
  _,unlocked=req('PUT',f"/admin/member/{target['id']}/lock",{'isLocked':False,'rowVersion':locked['rowVersion']},at)
  user=login(emails[0],'New-'+password)
  _,promoted=req('PUT',f"/admin/member/{target['id']}/role",{'roleId':2,'rowVersion':unlocked['rowVersion']},at)
  req('GET','/member/me',token=user['token'],expected=401)
  promoted_login=login(emails[0],'New-'+password)
  req('GET','/admin/member',token=promoted_login['token'])
  check(promoted_login['member']['role']=='Admin','role change revokes old token and grants role on new login')
  req('PUT',f"/admin/member/{target['id']}/role",{'roleId':1,'rowVersion':promoted['rowVersion']},promoted_login['token'],409)
  req('PUT',f"/admin/member/{admin['member']['id']}/lock",{'isLocked':True,'rowVersion':admin['member']['rowVersion']},at,409)
  check(True,'Admin cannot lock or demote own account')
  req('PUT',f"/admin/member/{target['id']}/role",{'roleId':999,'rowVersion':promoted['rowVersion']},at,400)
  check(True,'unknown role rejected')
  _,demoted=req('PUT',f"/admin/member/{target['id']}/role",{'roleId':1,'rowVersion':promoted['rowVersion']},at)
  req('GET','/admin/member',token=promoted_login['token'],expected=401)
  check(demoted['role']=='Member','role removal invalidates existing Admin access')
  _,other=req('GET',f"/admin/member/{people[1]['id']}",token=at)
  _,edited=req('PUT',f"/admin/member/{other['id']}",{'givenName':'AdminEdited','surname':tag,'phone':'0900000001','rowVersion':other['rowVersion']},at)
  check(edited['givenName']=='AdminEdited','Admin can edit member profile')
  _,categories=req('GET','/category')
  check(len(categories)==4,'seed categories are available')
  subprocess.run(['powershell','-NoProfile','-File',str(ROOT/'tests/database_checks.ps1'),'-Mode','Check','-RunTag',tag],check=True,capture_output=True)
  check(True,'23 tables, seed, migration, rowversion, hashed credentials and role FK')
  # Applying migrations and seed again must preserve existing admin credentials and counts.
  subprocess.run(['dotnet','run','--project','WebApi','--no-build','--no-launch-profile','--','--init-db','--init-only'],cwd=ROOT,check=True,capture_output=True)
  subprocess.run(['powershell','-NoProfile','-File',str(ROOT/'tests/database_checks.ps1'),'-Mode','Check','-RunTag',tag],check=True,capture_output=True)
  check(True,'migrations and seed are safe to rerun')
 finally:cleanup(tag)
 print(f'COMPLETE: {passed} checks passed; own test accounts cleaned.',flush=True)
if __name__=='__main__':run()
