# Event & Reminder App (Lab 11) 📅

แอปพลิเคชันสำหรับจัดการตารางเวลากิจกรรมและการแจ้งเตือน (Offline) พัฒนาด้วย **Flutter**, จัดการฐานข้อมูลด้วย **SQLite (sqflite)**, และจัดการ State ของแอปพลิเคชันด้วย **Provider**

---

## 🚀 วิธีรัน (How to Run)

1. ตรวจสอบให้แน่ใจว่าติดตั้ง Flutter SDK ในเครื่องเรียบร้อยแล้ว
2. Clone repository นี้ลงในเครื่องของคุณ
3. เปิด Terminal แล้วเข้าไปที่โฟลเดอร์ของโปรเจกต์
4. รันคำสั่งเพื่อติดตั้งแพ็กเกจที่จำเป็น:
   flutter pub get
5. สั่งรันแอปพลิเคชัน (แนะนำให้รันบน Android Emulator หรือ iOS Simulator):
   flutter run

*(หมายเหตุ: โปรเจกต์นี้มีการตั้งค่า sqflite_common_ffi ไว้แล้ว สามารถกดรันบน macOS / Windows ได้เช่นกัน)*

---

## 🗄️ โครงสร้างตาราง (Database Structure)

ฐานข้อมูลออกแบบโดยมี 3 ตารางหลักที่มีความสัมพันธ์กัน (Relational Database) ดังนี้ :

### 1. ตาราง categories (ประเภทกิจกรรม)
* id (INTEGER, PRIMARY KEY, AUTOINCREMENT)
* name (TEXT, NOT NULL) - ชื่อประเภท
* color_hex (TEXT, NOT NULL) - สีประจำประเภท
* icon_key (TEXT, NOT NULL) - ชื่อไอคอน
* created_at (TEXT, NOT NULL)
* updated_at (TEXT, NOT NULL)

### 2. ตาราง events (กิจกรรม)
* id (INTEGER, PRIMARY KEY, AUTOINCREMENT)
* title (TEXT, NOT NULL) - ชื่อกิจกรรม
* description (TEXT) - รายละเอียดเพิ่มเติม
* category_id (INTEGER, NOT NULL) - FK เชื่อมกับ categories(id)
* event_date (TEXT, NOT NULL) - วันที่จัดกิจกรรม (YYYY-MM-DD)
* start_time (TEXT, NOT NULL) - เวลาเริ่ม (HH:mm)
* end_time (TEXT, NOT NULL) - เวลาสิ้นสุด (HH:mm)
* status (TEXT, NOT NULL) - สถานะ (pending, in_progress, completed, cancelled)
* priority (INTEGER, NOT NULL) - ระดับความสำคัญ (1-3)
* created_at (TEXT, NOT NULL)
* updated_at (TEXT, NOT NULL)

### 3. ตาราง reminders (การแจ้งเตือน)
* id (INTEGER, PRIMARY KEY, AUTOINCREMENT)
* event_id (INTEGER, NOT NULL) - FK เชื่อมกับ events(id) (ON DELETE CASCADE)
* minutes_before (INTEGER, NOT NULL) - แจ้งเตือนล่วงหน้า (นาที)
* remind_at (TEXT, NOT NULL) - วันเวลาที่แจ้งเตือนจริง (คำนวณจากเวลาเริ่ม - นาที)
* is_enabled (INTEGER, NOT NULL) - เปิด/ปิดแจ้งเตือน (0 หรือ 1)

---

## ✨ รายการฟีเจอร์ที่ทำได้ (Features)

แอปพลิเคชันนี้ทำงานได้ครบถ้วนตาม Functional Requirements ดังนี้ :

1. **Category Management (จัดการประเภทกิจกรรม)** 
   - เพิ่ม แก้ไข และลบประเภทกิจกรรมได้
   - เลือกสีประจำประเภทได้
   - ป้องกันการลบประเภทหากมีกิจกรรมที่ใช้งานประเภทนี้อยู่ (Foreign Key Constraints)

2. **Event Management (จัดการกิจกรรม)** 
   - ทำ CRUD (เพิ่ม, ดู, แก้ไข, ลบ) กิจกรรมได้อย่างสมบูรณ์
   - ตรวจสอบความถูกต้อง (Validation): เวลาสิ้นสุดต้องมากกว่าเวลาเริ่มเสมอ (End > Start)

3. **Status Tracking (ติดตามสถานะ)** 
   - เปลี่ยนสถานะกิจกรรมได้ 4 แบบ: ยังไม่เริ่ม (Pending), กำลังทำ (In Progress), เสร็จสิ้น (Completed), และ ยกเลิก (Cancelled) 
   - ระบบจะปิดการแจ้งเตือนอัตโนมัติหากเปลี่ยนสถานะเป็น Completed หรือ Cancelled

4. **Reminders Logic (ระบบแจ้งเตือน)** 
   - สามารถเลือกเปิด/ปิด และตั้งเวลาแจ้งเตือนล่วงหน้าได้ (เช่น 5, 10, 15 นาที)
   - บันทึกการคำนวณเวลาลงฐานข้อมูลตาราง Reminders ถูกต้อง

5. **Advanced Filters & Sort (ระบบค้นหาและกรองข้อมูล)** 
   - ค้นหากิจกรรมจากชื่อ (Search)
   - กรองข้อมูลตามช่วงเวลา (ทั้งหมด, วันนี้, เดือนนี้)
   - กรองข้อมูลตามสถานะ (Pending, In Progress, ฯลฯ)
   - เรียงลำดับรายการตามเวลาที่ใกล้ที่สุด หรือ ตามเวลาที่อัปเดตล่าสุดได้

---

## 📸 Screenshots (รูปภาพหน้าจอ)

*(นำภาพ Screenshot ของแอปไปใส่ไว้ในโฟลเดอร์โปรเจกต์ เช่น สร้างโฟลเดอร์ assets/screenshots/ แล้วเปลี่ยนลิงก์ด้านล่างให้ตรงกับชื่อไฟล์รูปของคุณ)*

**1. หน้าหลัก และ รายการกิจกรรม (Home Screen)**

<img width="300"  alt="image" src="https://github.com/user-attachments/assets/275406de-a896-4352-937c-f168bd76227b" />



**2. หน้าฟอร์มเพิ่ม/แก้ไขกิจกรรม (Event Form + Validation)**

<img width="300" alt="image" src="https://github.com/user-attachments/assets/4f74d485-e8c3-4e0c-b0e8-6a179ba9bdb2" />


**3. หน้ารายละเอียดกิจกรรมและการเปลี่ยนสถานะ (Event Detail)**

<img width="300" alt="image" src="https://github.com/user-attachments/assets/0fd7e12a-5728-489e-a89e-dbcfa792000f" />


**4. หน้าจัดการประเภทกิจกรรม (Category Management)**

<img width="300" alt="image" src="https://github.com/user-attachments/assets/95681c59-b174-4184-bb50-e0c1ce366243" />


**5. เมนูตัวกรองข้อมูล (Filter Dialog)**

<img width="300" alt="image" src="https://github.com/user-attachments/assets/510bf184-50f3-4f80-a0bb-203d2d1e5ae6" />
