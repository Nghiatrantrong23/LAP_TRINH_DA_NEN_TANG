"""Stage3 catalog checks against localhost:5290 + the local development database.
Creates TEST3 fixtures and cleans only the exact generated run tag.
"""
import base64,concurrent.futures,json,pathlib,subprocess,threading,time,urllib.request,urllib.error,urllib.parse,uuid
ROOT=pathlib.Path(__file__).resolve().parents[1]
BASE='http://localhost:5290/api'
PNG=base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=')
passed=0

def check(value,label):
 global passed
 assert value,label
 passed+=1;print('PASS '+label,flush=True)

def send(method,path,body=None,token=None,expected=200,image=None,form=False):
 headers={}
 if token:headers['Authorization']='Bearer '+token
 if form:
  boundary='catalog-'+uuid.uuid4().hex;chunks=[]
  for key,value in (body or {}).items():
   chunks.append((f'--{boundary}\r\nContent-Disposition: form-data; name="{key}"\r\n\r\n{value}\r\n').encode())
  if image is not None:chunks.append((f'--{boundary}\r\nContent-Disposition: form-data; name="image"; filename="../../ignored.svg"\r\nContent-Type: image/svg+xml\r\n\r\n').encode()+image+b'\r\n')
  chunks.append(f'--{boundary}--\r\n'.encode());data=b''.join(chunks);headers['Content-Type']='multipart/form-data; boundary='+boundary
 else:
  data=None if body is None else json.dumps(body).encode();headers['Content-Type']='application/json'
 request=urllib.request.Request(BASE+path,data=data,headers=headers,method=method)
 try:
  with urllib.request.urlopen(request,timeout=30) as r:status,raw=r.status,r.read()
 except urllib.error.HTTPError as e:status,raw=e.code,e.read()
 value=json.loads(raw) if raw else None
 if expected is not None:assert status==expected,(method,path,status,value)
 return status,value

def local_image(path):return ROOT/'WebApi/wwwroot'/path.lstrip('/')
def removed(paths):
 deadline=time.monotonic()+25
 while time.monotonic()<deadline:
  if all(not local_image(path).exists() for path in paths):return True
  time.sleep(.25)
 return False

def run():
 tag=uuid.uuid4().hex[:10];print('Catalog test run '+tag,flush=True)
 cfg=json.loads((ROOT/'WebApi/appsettings.json').read_text(encoding='utf-8-sig'))
 _,login=send('POST','/auth/login',{'email':cfg['Seed']['AdminEmail'],'password':cfg['Seed']['AdminPassword']});admin=login['token']
 court_id=service_id=0
 paths=[]
 def fixture(mode):
  subprocess.run(['powershell','-NoProfile','-File',str(ROOT/'tests/catalog_fixture.ps1'),'-Mode',mode,'-RunTag',tag,'-CourtId',str(court_id),'-ServiceId',str(service_id)],check=True,capture_output=True)
 def endpoint(kind,item):return f"/admin/{kind}/{item['id']}?rowVersion="+urllib.parse.quote(item['rowVersion'],safe='')
 try:
  send('GET','/admin/category',expected=401)
  email=f'catalog-{tag}@example.com'
  send('POST','/auth/register',{'email':email,'password':'Password-'+tag,'givenName':'TEST3','surname':tag},expected=201)
  _,member=send('POST','/auth/login',{'email':email,'password':'Password-'+tag});mt=member['token']
  send('GET','/admin/product',token=mt,expected=403)
  send('POST','/admin/category',{'name':'Not allowed'},mt,403,form=True)
  check(True,'catalog CRUD requires Admin')
  send('GET','/admin/product?pageSize=101',token=admin,expected=400)
  send('GET','/admin/category?pageIndex=0',token=admin,expected=400)
  check(True,'catalog pagination bounds')
  cat_fields={'name':'TEST3 Category '+tag,'description':'Initial','displayOrder':'5','isActive':'true'}
  _,cat=send('POST','/admin/category',cat_fields,admin,201,PNG,True);paths.append(cat['imagePath'])
  check(local_image(cat['imagePath']).is_file() and cat['imagePath'].endswith('.png') and 'ignored' not in cat['imagePath'],'category image uses validated bytes and server filename')
  send('POST','/admin/category',cat_fields,admin,409,form=True)
  check(True,'duplicate category rejected')
  _,edited=send('PUT',f"/admin/category/{cat['id']}",{**cat_fields,'description':'Changed','rowVersion':cat['rowVersion']},admin,form=True)
  check(edited['imagePath']==cat['imagePath'] and edited['rowVersion']!=cat['rowVersion'],'metadata edit keeps image and updates rowversion')
  send('PUT',f"/admin/category/{cat['id']}",{**cat_fields,'rowVersion':cat['rowVersion']},admin,409,form=True)
  check(True,'stale category update rejected')
  _,replaced=send('PUT',f"/admin/category/{cat['id']}",{**cat_fields,'rowVersion':edited['rowVersion']},admin,image=PNG,form=True);paths.append(replaced['imagePath'])
  check(replaced['imagePath']!=cat['imagePath'] and removed([cat['imagePath']]),'category replacement removes old physical image')
  cat=replaced
  send('POST','/admin/category',{'name':'TEST3 Bad '+tag},admin,415,b'<svg>'+b'x'*100+b'</svg>',True)
  check(True,'SVG/fake image upload rejected')
  send('POST','/admin/category',{'name':'TEST3 Huge '+tag},admin,400,b'x'*(5*1024*1024+1),True)
  check(True,'oversized image rejected')
  _,venues=send('GET','/admin/venue',token=admin)
  fields={'name':'TEST3 Court '+tag,'description':'Indoor court','categoryId':cat['id'],'venueId':venues[0]['id'],'type':'Court','basePrice':'100000','unit':'giờ','isActive':'true','capacity':'4','indoor':'true','surface':'Thảm','openTime':'06:00','closeTime':'22:00','peakStartTime':'17:00','peakEndTime':'21:00','peakPrice':'180000'}
  send('POST','/admin/product',fields,admin,400,form=True)
  check(True,'new product requires image')
  send('POST','/admin/product',{**fields,'peakStartTime':'05:00'},admin,400,PNG,True)
  send('POST','/admin/product',{**fields,'openTime':'06:15'},admin,400,PNG,True)
  send('POST','/admin/product',{**fields,'basePrice':'-1'},admin,400,PNG,True)
  send('POST','/admin/product',{**fields,'categoryId':'-1'},admin,400,PNG,True)
  check(True,'court hours, peak hours, price and category validation')
  _,court=send('POST','/admin/product',fields,admin,201,PNG,True);court_id=court['id'];paths.append(court['imagePath'])
  check(court['capacity']==4 and court['peakPrice']==180000 and court['openTime']=='06:00:00','court creation stores profile and pricing')
  svc={k:fields[k] for k in ['categoryId','venueId','isActive']};svc.update(name='TEST3 Service '+tag,type='Service',basePrice='10000',unit='chai')
  _,service=send('POST','/admin/product',svc,admin,201,PNG,True);service_id=service['id'];paths.append(service['imagePath'])
  check(service['capacity'] is None and service['type']=='Service','service does not create court profile')
  _,page=send('GET',f"/product?search={tag}&categoryId={cat['id']}&pageSize=1")
  check(page['totalItems']==2 and page['totalPages']==2 and len(page['items'])==1,'public product filtering and pagination')
  send('DELETE',endpoint('category',cat),token=admin,expected=409)
  check(local_image(cat['imagePath']).exists(),'blocked category delete keeps image')
  old_image=court['imagePath']
  _,court2=send('PUT',f'/admin/product/{court_id}',{**fields,'rowVersion':court['rowVersion'],'description':'New photo'},admin,image=PNG,form=True);paths.append(court2['imagePath'])
  check(removed([old_image]) and local_image(court2['imagePath']).exists(),'product replacement deletes old file and keeps new one')
  send('PUT',f'/admin/product/{court_id}',{**fields,'rowVersion':court['rowVersion']},admin,409,form=True)
  check(True,'stale product update rejected')
  send('PUT',f'/admin/product/{court_id}',{**fields,'rowVersion':court2['rowVersion'],'type':'Service'},admin,409,form=True)
  check(True,'product type cannot be changed')
  before_uploads=set((ROOT/'WebApi/wwwroot/uploads').rglob('*.*'))
  gate=threading.Barrier(2)
  def update(n):
   gate.wait();return send('PUT',f'/admin/product/{court_id}',{**fields,'description':f'Concurrent {n}','rowVersion':court2['rowVersion']},admin,expected=None,image=PNG,form=True)
  with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:results=list(pool.map(update,range(2)))
  check(sorted(v[0] for v in results)==[200,409],'concurrent edits cannot overwrite each other')
  court=next(v[1] for v in results if v[0]==200);paths.append(court['imagePath'])
  new_uploads=set((ROOT/'WebApi/wwwroot/uploads').rglob('*.*'))-before_uploads
  check(new_uploads=={local_image(court['imagePath'])},'failed concurrent image edit does not orphan its upload')
  fixture('Cart')
  send('DELETE',endpoint('product',service),token=admin,expected=409)
  check(local_image(service['imagePath']).exists(),'product in cart cannot be deleted')
  fixture('ClearCart');fixture('Order');fixture('Check')
  send('DELETE',endpoint('product',court),token=admin,expected=409)
  check(local_image(court['imagePath']).exists(),'product in historical order cannot be deleted')
  before_uploads=set((ROOT/'WebApi/wwwroot/uploads').rglob('*.*'))
  send('PUT',f'/admin/product/{court_id}',{**fields,'rowVersion':court['rowVersion'],'isActive':'false'},admin,409,image=PNG,form=True)
  check(not(set((ROOT/'WebApi/wwwroot/uploads').rglob('*.*'))-before_uploads),'business validation failure compensates staged image')
  check(True,'active booking prevents disabling court')
  _,court=send('PUT',f'/admin/product/{court_id}',{**fields,'rowVersion':court['rowVersion'],'basePrice':'130000'},admin,form=True)
  fixture('Check');check(court['basePrice']==130000,'price edit preserves historical order totals')
  fixture('CompleteOrder')
  _,court=send('PUT',f'/admin/product/{court_id}',{**fields,'rowVersion':court['rowVersion'],'isActive':'false'},admin,form=True)
  send('GET',f'/product/{court_id}',expected=404)
  send('GET',f'/admin/product/{court_id}',token=admin)
  check(True,'inactive product hidden publicly but visible to Admin')
  _,hidden_cat=send('PUT',f"/admin/category/{cat['id']}",{**cat_fields,'rowVersion':cat['rowVersion'],'isActive':'false'},admin,form=True)
  send('GET',f'/product/{service_id}',expected=404)
  check(True,'inactive category hides its products')
  # Delete unused service and verify physical file lifecycle.
  send('DELETE',endpoint('product',service),token=admin,expected=204)
  check(removed([service['imagePath']]),'product delete removes physical image')
  # A separate empty category can be deleted with its image.
  _,empty=send('POST','/admin/category',{'name':'TEST3 Empty '+tag,'isActive':'true'},admin,201,PNG,True);paths.append(empty['imagePath'])
  send('DELETE',f"/admin/category/{empty['id']}",token=admin,expected=400)
  send('DELETE',endpoint('category',empty),token=admin,expected=204)
  check(removed([empty['imagePath']]),'category delete requires version and removes image')
 finally:fixture('Cleanup')
 check(removed(paths),'all test image files cleaned')
 print(f'COMPLETE: {passed} catalog checks passed; own fixtures cleaned.',flush=True)
if __name__=='__main__':run()
