# Cursor RTL FA

استایل راست‌چین و فونت IRANSans برای چت و پلن Cursor (با افزونه Custom UI Style).

---

## پیش‌نیاز

- [Cursor](https://cursor.com) editor
- افزونه [Custom UI Style](https://marketplace.visualstudio.com/items?itemName=subframe7536.custom-ui-style) (در Cursor نصب شود)
- فونت **IRANSans** روی سیستم نصب باشد (یا از `Tahoma` استفاده می‌شود)

---

## روش ۱: کپی دستی

1. فایل **[settings-snippet.json](settings-snippet.json)** را باز کن.
2. محتوای آن را کپی کن.
3. در Cursor: `Ctrl+,` → دکمه **Open Settings (JSON)** (آیکون `{}`).
4. کلیدهای داخل snippet را داخل `settings.json` اضافه یا ادغام کن (اگر از قبل `custom-ui-style.stylesheet` داری، با همین جایگزین کن).
5. ذخیره کن و در Cursor دستور **Custom UI Style: Reload** را اجرا کن.

---

## روش ۲: اسکریپت (اضافه خودکار به تنظیمات)

### ویندوز

- **روش آسان:** روی **install.ps1** راست‌کلیک کن → **Run with PowerShell**.
- یا در PowerShell از پوشه پروژه:
  ```powershell
  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force   # فقط یک بار در صورت خطای اجرا
  .\install.ps1
  ```

اسکریپت این کارها را انجام می‌دهد:
- اگر دستور CLI مربوط به Cursor در سیستم موجود باشد و افزونه **Custom UI Style** نصب نباشد، آن را نصب می‌کند.
- تنظیمات فعلی Cursor را **بکاپ** می‌گیرد و استایل RTL را به `settings.json` اضافه/به‌روز می‌کند.
- برای جلوگیری از خطای `EPIPE`، Cursor را اجباری نمی‌بندد؛ در پایان پیام می‌دهد که `Custom UI Style: Reload` را اجرا کنی.

---

## ماندگاری تنظیمات بعد از آپدیت Cursor

تنظیمات در فایل **کاربر** ذخیره می‌شوند (`%APPDATA%\Cursor\User\settings.json`) و معمولاً با آپدیت Cursor **پاک نمی‌شوند**. اگر بعد از یک آپدیت استایل از بین رفت:

1. **دوباره اسکریپت را اجرا کن:** `.\install.ps1` — تنظیمات دوباره اعمال و Cursor ریستارت می‌شود.
2. این مخزن را نگه دار تا در هر زمان بتوانی با یک اجرای `install.ps1` تنظیمات را بازگردانی کنی.

---

## محتوای استایل

- متن چت (پاراگراف، عناوین، لیست، نقل‌قول، جدول): **راست‌چین (RTL)**، فونت IRANSans، سایز ۱۶px، فاصله خط ۱.۸.
- ویرایشگر **Plan** (`.plan-editor`): همان استایل RTL برای متن، عناوین، لیست‌ها و جدول‌ها.
- بخش **To-dos** و **Referenced Agents** در پلن: راست‌چین با فونت IRANSans.
- بلوک‌های کد (`pre` / `code`) در پلن: **چپ‌چین (LTR)** با فونت monospace.
- **پیش‌نمایش فایل‌های Markdown** در Cursor: از ویرایشگر React با کلاس `.markdown-editor-react` استفاده می‌شود (نه preview کلاسیک VS Code). استایل از طریق `custom-ui-style` اعمال می‌شود.
- برای preview کلاسیک VS Code (در صورت استفاده): `markdown-preview.css` در workspace با `.vscode/settings.json`.

---

## لایسنس

MIT
