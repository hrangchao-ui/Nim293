# เพลงมันวัยเก๋า — Neon Jukebox + Supabase

## ไฟล์ที่ได้รับ
- index.html / style.css / app.js : Web App สำหรับมือถือแนวตั้งและ PC
- assets/cover.png : ภาพหน้าตู้เพลง
- supabase_setup.sql : สร้าง Database + Storage bucket + RLS + Realtime

## วิธีตั้งค่า (ทำครั้งแรก)
1. เข้า https://supabase.com/dashboard เลือกโปรเจกต์ nhlwexaydsvyzilsconc ที่คุณสร้างแล้ว
2. เปิด SQL Editor วางเนื้อหาจาก `supabase_setup.sql` แล้วกด Run
3. ไปที่ Authentication > Users สร้าง Admin ด้วยอีเมลและรหัสผ่าน (หรือ Invite)
4. คัดลอก UUID ของ Admin ที่สร้าง ไปที่ SQL Editor และรัน:
   insert into public.admin_users(user_id) values ('ใส่-UUID-ของ-Admin-ที่นี่') on conflict do nothing;
5. Project URL และ Publishable Key ตั้งค่าไว้แล้วใน app.js ไม่ต้องกรอกซ้ำ
6. เปิดเว็บผ่าน HTTPS hosting หรือ localhost (ไม่แนะนำเปิด file:// โดยตรง)
7. เว็บจะเชื่อมต่อโปรเจกต์ที่กำหนดไว้อัตโนมัติ; ปุ่ม "☁ เชื่อมต่อ" ใช้ตรวจหรือเปลี่ยนการตั้งค่า
8. กด "⚙ Admin" ล็อกอินด้วยอีเมล/รหัสผ่านที่ตั้งไว้
9. อัปโหลดเพลง MP3/M4A/WAV/OGG หรือเพิ่มลิงก์ HTTPS ของไฟล์เสียงโดยตรง
10. เครื่องอื่นเปิด Web App เวอร์ชันนี้ ก็จะเชื่อมต่อโปรเจกต์เดียวกันโดยอัตโนมัติ

## วิธีทดลองบนคอม
- มี Python: เปิด terminal ในโฟลเดอร์นี้ พิมพ์ `python -m http.server 8000`
- เข้า `http://localhost:8000`
- หรืออัปโหลดโฟลเดอร์ขึ้น Netlify / Vercel / Cloudflare Pages แบบ static web

## การเล่นเพลงและคิว
- แตะเพลงเพื่อเล่น / แตะ + เพื่อเพิ่มคิว / ลูกศรเพื่อสลับลำดับ / X เพื่อลบจากคิว
- คิวเพลงเก็บในแท็บของผู้ฟัง ไม่ใช่คิวส่วนกลางข้ามเครื่อง
- EQ ใช้ Web Audio API วิเคราะห์เสียงจาก audio element จริง; เว็บภายนอกอาจไม่อนุญาต CORS
- รายการเพลงรีเฟรชทันทีเมื่อเปิดใช้งาน Realtime และมี polling ทุก 45 วินาทีสำรอง

## สิทธิ์และข้อควรทราบ
- ห้ามใส่ service_role / secret key ใน Web App; ใช้เฉพาะ publishable หรือ legacy anon key เท่านั้น
- กำหนดสิทธิ์ Admin ที่ฝั่ง Supabase SQL/RLS; การล็อกอินอย่างเดียวไม่ได้ให้สิทธิ์เพิ่ม/ลบ
- Bucket `songs` เป็น Public เพื่อเปิดเล่นเพลงโดยไม่ล็อกอิน จึงต้องใช้เฉพาะไฟล์ที่ได้รับอนุญาตให้เผยแพร่
- อัปโหลดไฟล์ไม่เกิน 50 MB และแนะนำ MP3 ที่เข้ารหัสมาตรฐานเพื่อให้เล่นได้หลายเบราว์เซอร์
- อัปโหลดจากเบราว์เซอร์แบบ standard upload; สำหรับไฟล์ขนาดใหญ่/เน็ตไม่เสถียรควรเปลี่ยนเป็น resumable uploads (TUS)
- การแก้ไขเพลงที่อัปโหลดอยู่แล้วโดยไม่เลือกไฟล์ใหม่จะคงไฟล์เดิมไว้
- หากลบข้อมูลเพลงสำเร็จแต่ลบไฟล์ Storage ล้มเหลว อาจมีไฟล์ค้าง ต้องตรวจใน Storage Dashboard
- URL กับ Publishable Key ถูกกำหนดเป็นค่าเริ่มต้นใน app.js; หากปรับค่าในหน้าตั้งค่าจะบันทึก override ใน localStorage ของเครื่องนั้น
- Supabase JS SDK และฟอนต์ Kanit ต้องใช้การเชื่อมต่ออินเทอร์เน็ต
- ต้องมีโปรเจกต์ Supabase จริงก่อน ถึงจะดึงหรืออัปโหลดเพลงออนไลน์ได้
- ไม่มีเพลงลิขสิทธิ์รวมอยู่ในไฟล์ ZIP

## สถานะการติดตั้ง
- ฝัง Project URL และ Publishable Key ที่ผู้ใช้ส่งมาแล้ว
- ยังไม่ได้สั่งรัน SQL ใน Supabase ของผู้ใช้, ยังไม่ได้สร้าง Admin และยังไม่ได้ deploy เว็บไซต์
- ถ้าระบบขึ้น error ว่า table public.songs does not exist ให้รัน supabase_setup.sql
- ถ้า Admin เข้าระบบได้แต่เพิ่ม/ลบไม่ได้ ให้ตรวจ admin_users UUID และ Storage/RLS
