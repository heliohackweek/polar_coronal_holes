pro general_full_cadence, zz, wlength, month=month,  $
                               start=start, finish = finish,  $
                               yyyy=yyyy

; CALLING:
; 	general_full_cadence, 'A', '171', month='01', yyyy='2011', start=1, finish=10 


rootDir = getenv('secchi') +'/wavelets/'
dir_save = rootDir

;**********************
;Modified by Silvina
dir_save = "/Users/guidoni/OneDrive\ -\ american.edu/Travel/Helio_hack_week/Wavelets/"
zz = 'A'
wlength = '171'
month= '01'
yyyy='2011'
start=1
finish=10

;create directories fits and pngs in dir_save
;**********************

spawn, 'mkdir ' + dir_save + 'fits/' + yyyy+month 
spawn, 'mkdir ' + dir_save + 'pngs/' + yyyy+month 
;spawn, 'mkdir ' + dir_save + 'fits/' + yyyy+month + '/' + wlength + '_' + zz
;spawn, 'mkdir ' + dir_save + 'pngs/' + yyyy+month + '/' + wlength + '_' + zz
 
mask = shift(dist(2048,2048),1024,1024)

;***********
;.compile what_euvi
;
;
;SEG: "The DIST function creates an array in which each array element value is proportional to its frequency
;/Applications/harris/idl87/lib
;more dist.pro
;
;
;R(i,j) = SQRT(F(i)^2 + G(j)^2)   where:
;                F(i) = i  IF 0 <= i <= n/2
;                     = n-i  IF i > n/2
;                G(i) = i  IF 0 <= i <= m/2
;                     = m-i  IF i > m/2
;
;SEG: plot mask to see what it does
;Found on github that DIST is this (see tests on "general_full_cadence_SEG_test.py):
;https://gist.githubusercontent.com/abeelen/453de325dd9787ea2aa7fad495f4f018/raw/6aefb8838695ec38bb4c345ad413d1ae354f99c1/dist.py
;dist(NAXIS):
;axis = np.linspace(-NAXIS/2+1, NAXIS/2, NAXIS)
;result = np.sqrt(axis**2 + axis[:,np.newaxis]**2)
;;np.newaxis increases the dimension of the existing array by one more dimension: 1D array will become 2D array, etc.
;return np.roll(result, NAXIS/2+1, axis=(0,1))
;The SHIFT function shifts elements of vectors or arrays along any dimension
;by any number of elements. Positive shifts are to the right while left shifts
; are expressed as a negative number. All shifts are circular.

testmaks = dist(5,5)
print, testmaks
TVSCL, mask

;***********
;SEG find indexes where mask is larger than 800
mask_idx = where(mask gt 800) 

timerange = ['0000','2400']
for t = start, finish do begin 
      ;SEG: create folders 
      ;SEG:STRCOMPRESS function returns a copy of String with 
      ;SEG:all whitespace (blanks and tabs) compressed to a single space or completely removed.
      strday = strcompress(string(t),/rem)
      strday = strmid('00',0,2-strlen(strday)) + strday
           print, 'mkdir ' + dir_save + 'pngs/' + yyyy+month + '/' + strday + '/' + wlength + '_' + zz
           spawn, 'mkdir ' + dir_save + 'pngs/' + yyyy+month + '/' + strday
              spawn, 'mkdir ' + dir_save + 'pngs/' + yyyy+month + '/' + strday + '/' + wlength + '_' + zz
           spawn, 'mkdir ' + dir_save + 'fits/' + yyyy+month + '/' + strday
              spawn, 'mkdir ' + dir_save + 'fits/' + yyyy+month + '/' + strday + '/' + wlength + '_' + zz
      ;SEG: create date string     
      day = yyyy + month + strday   
      w = what_euvi(day, timerange, sc=zz, wlength = wlength)
      if (t eq start) then files = w else files = [files, w]
 endfor
 files = files(sort(files))
 
 iiidx = where(files ne '', ct)
 if (ct gt 0) then files = files(iiidx)
 nn = n_elements(files)

 if (zz eq 'A') then view = 'R'
 if (zz eq 'B') then view = 'L'

 k = [[1,1,1],[1,3,1],[1,1,1]]
 
for q = 0,nn-1 do begin
      print, ' -----------------------------: ', q, nn-1
              
      print, ' Processing...:', files(q)
      secchi_prep, files(q), outhdr, img, outsize = 2048, $
                             /rotate_on, /calimg_off , /cubic
                  
      img = alog(img>0.01)
      img_orig = img

      img = sigma_filter(img,radius=3,/iterate)
      img(mask_idx) = (sigma_filter(img,radius=13,/iterate))(mask_idx)
              
       mr = kconvol(img,30)
       for t=0,50 do mr = kconvol(mr,30)
             
       img1 = kconvol(img,k,total(k)) 
       img1 = kconvol(img1,k,total(k)) 
       l0 = kconvol(img1,k,total(k))

       c =  (img1-mr*.9^2.5 + (img1-l0)*12. )   
       d = img/((img-c)>25) >1<2     
       e = c*d^.5
       e_sin_label = e
       
       e(where(mask gt 1030)) = 0
       
       dhm =  strmid(files(q),strlen(files(q))-25,15)
       PUT_TEXT, e,TEXTARRAY('EUVI ' + strupcase(zz) + ' ('+wlength+'): ' +dhm +' UT',charsize =5,charthick=2,font=1),.02,.01,/NORMAL
       file_save_fits = strmid(files(q),strlen(files(q))-25,16)+wlength+'eu_'+view+'.fts' 
       ddd = strmid(files(q),strlen(files(q))-19,2)
        if zz eq 'A' then file_save_fits = dir_save + 'fits/' + strmid(day,0,6) + '/' + ddd + '/' + wlength+'_A/'+file_save_fits
        if zz eq 'B' then file_save_fits = dir_save + 'fits/' + strmid(day,0,6) + '/' + ddd + '/' + wlength+'_B/'+file_save_fits
        ; if zz eq 'A' then file_save_fits = dir_save + 'fits/' + strmid(day,0,6) + '/' + strmid(day,6,2) + '/' + wlength+'_A/'+file_save_fits
        ; if zz eq 'B' then file_save_fits = dir_save + 'fits/' + strmid(day,0,6) + '/' + strmid(day,6,2) + '/' + wlength+'_B/'+file_save_fits
     
       ;sccwritefits, '/Volumes/Disk2/dummy.fts', e_sin_label, outhdr
       sccwritefits, file_save_fits, e_sin_label, outhdr
       spawn, 'gzip ' + file_save_fits
       ;spawn, 'mv /Volumes/Disk2/dummy.fts.gz ' + file_save_fits + '.gz'
 
       file_save = strmid(files(q),strlen(files(q))-25,16)+wlength+'eu_'+view+'.png'   
       if zz eq 'A' then file_save = dir_save + 'pngs/' + strmid(day,0,6) +'/' + ddd + '/' + wlength+'_A/'+file_save
       if zz eq 'B' then file_save = dir_save + 'pngs/' + strmid(day,0,6) +'/' + ddd + '/' + wlength+'_B/'+file_save
       ; if zz eq 'A' then file_save = dir_save + 'pngs/' + strmid(day,0,6) +'/' + strmid(day,6,2) + '/' + wlength+'_A/'+file_save
       ; if zz eq 'B' then file_save = dir_save + 'pngs/' + strmid(day,0,6) +'/' + strmid(day,6,2) + '/' + wlength+'_B/'+file_save
   
       if (wlength eq '304') then begin
          eit_colors, 304
          tvlct, /get, rr, gg, bb
          write_png, file_save, bytscl(e,-1.0,3.6), rr, gg, bb
          loadct, 0
       endif

       if (wlength eq '284') then begin
          eit_colors, 284
          tvlct, /get, rr, gg, bb
          write_png, file_save, bytscl(e,-1.75,3.9), rr, gg, bb
          loadct, 0
       endif

       if (wlength eq '195') then begin
          eit_colors, 195
          tvlct, /get, rr, gg, bb
          write_png, file_save, bytscl(e,-1.7,3.8), rr, gg, bb
          loadct, 0
       endif

       if (wlength eq '171') then begin
          loadct, 0                  
          ;eit_colors, 171
          tvlct, /get, rr, gg, bb
          rr = (1.5*rr-150)>0<255
          gg = (gg+10)<255      
          bb = (bb+130)<255
          write_png, file_save, bytscl((e>0.01)^0.8,0.25,2.75), rr, gg, bb
          loadct, 0
       endif

 
    nada:
    
  endfor     
finnada:

end
