# 🛠️ Tailwind v4 "Cannot find native binding" — Fix Guide

This guide explains how to **identify and permanently fix** the Tailwind v4 oxide native binding error that commonly occurs in modern Next.js projects.

---

## ❗ Symptoms

You may encounter a build error similar to:

```
Error evaluating Node.js code
Cannot find native binding
Cannot find module '@tailwindcss/oxide-linux-x64-gnu'
```

Usually triggered while building:

```
./app/globals.css
```

Common environments affected:

- Next.js 15 / 16 (Turbopack)
- Tailwind CSS v4
- Linux / WSL / Docker
- npm v10+

---

## 🧠 Root Cause

Tailwind v4 uses a **native Rust engine** called `oxide` for faster compilation.

It relies on platform‑specific binaries installed as **optional dependencies**:

```
@tailwindcss/oxide-linux-x64-gnu
```

Due to an npm bug, optional dependencies are sometimes skipped during installation, leaving Tailwind unable to load its native binary.

---

## ✅ Quick Diagnosis

Run:

```bash
ls node_modules/@tailwindcss
```

If you do **NOT** see:

```
oxide-linux-x64-gnu
```

then the binary was never installed.

---

## ✅ Definitive Fix (Recommended)

### 1️⃣ Install the missing binary manually

```bash
npm install -D @tailwindcss/oxide-linux-x64-gnu
```

---

### 2️⃣ Clear Next.js build cache

```bash
rm -rf .next
```

---

### 3️⃣ Restart development server

```bash
npm run dev
```

✅ The project should now compile successfully.

---

## 🔒 Permanent Prevention

Create a file named:

```
.npmrc
```

Inside your project root and add:

```
include=optional
```

This forces npm to always install optional native dependencies.

---

## 🧹 Full Clean Reinstall (If Problems Persist)

```bash
rm -rf node_modules package-lock.json
npm cache clean --force
npm install --include=optional
```

---

## ✅ Recommended Environment

| Tool | Recommended Version |
|------|--------------------|
| Node.js | 20 LTS |
| npm | 10+ |
| Tailwind | v4 |
| Next.js | 15+ |

---

## 🔎 Verification Checklist

After installation ensure:

- `node_modules/@tailwindcss/oxide` exists
- `node_modules/@tailwindcss/oxide-linux-x64-gnu` exists
- `npm run dev` starts without CSS errors

---

## 🚨 When This Usually Happens

- Pulling a repo created on another OS
- Upgrading Node.js
- Switching between Docker / host installs
- Fresh clone + npm install
- Clearing caches or lockfiles

---

## 💡 Optional Stability Tip

If working in Docker or WSL:

👉 Always run `npm install` **inside the same environment** where Next.js runs.

---

## ✅ Summary

The error is not caused by your CSS or Tailwind configuration.

It occurs because npm skips Tailwind’s native binary dependency.

Installing the correct oxide package and enabling optional dependencies permanently resolves the issue.

---

**Keep this guide in your repo** (e.g., `docs/tailwind-fix.md`) so future setup issues can be resolved in minutes.

