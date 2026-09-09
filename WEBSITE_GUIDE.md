# 🌐 ShivaayMusic Website — Poori Free-Hosting Guide (Render + Vercel)

Ye guide batayegi kaise **ek dum free** me apni music website live karoge.
Koi YouTube API key, koi credit card — **kuch nahi chahiye.**

## Is setup me 2 cheezein hain

| Part | Kya hai | Kahan host hoga | Cost |
|---|---|---|---|
| `server/` | Dart backend — YouTube se songs search + stream URL nikaalta hai | **Render (free)** | ₹0 |
| `website/` | Player website (search + play UI) | **Vercel (free)** | ₹0 |

Flow:
```
Browser (website)  ──►  tumhara Render server  ──►  YouTube (bina API key ke)
     (audio)       ◄──  stream URL / bytes
```

---

# Part 1 — Server: Render pe FREE deploy

### Step 1.1: Render account banao
1. https://render.com kholo → **Get Started** → **Sign up with GitHub** (apna Shivaay20005 GitHub connect kar do — sabse easy).

### Step 1.2: Web Service banao
1. Dashboard pe **New + → Web Service** dabao.
2. **Connect a repository** me apna repo `ShivaayMusic-main` select karo
   (pehli baar me "Configure GitHub App" pe repo ka access dena padega).
3. Ab settings bharo:

| Setting | Kya daalna hai |
|---|---|
| **Name** | `shivaaymusic-server` (kuch bhi unique) |
| **Region** | `Singapore` (India ke liye sabse fast) |
| **Branch** | `arena/01a0841c-shivaaymusic-main` |
| **Root Directory** | `server`  ← **bahut zaroori!** |
| **Language/Runtime** | `Docker` (Render khud `server/Dockerfile` dhoondh lega) |
| **Instance Type** | **Free** |

4. **Create Web Service** dabao.

### Step 1.3: Live hone ka wait karo (~5-8 min)
- Logs me build chalegi: Dart SDK download → `dart pub get` → compile → 
  Aakhir me dikhega: `shivaaymusic-server listening on http://0.0.0.0:10000` → status **Live 🟢**
- Upar URL milegi, kuch aisi: `https://shivaaymusic-server.onrender.com` — **copy kar lo.**

### Step 1.4: Test karo (browser me hi)
- `https://tumhara-url.onrender.com/healthcheck` → `{"status":"ok"}` dikhna chahiye
- `https://tumhara-url.onrender.com/api/stream/dQw4w9WgXcQ` → JSON me `"url":"https://rr...googlevideo.com/..."` aana chahiye

> ⚠️ **Free tier ki limit:** 15 min bina request → server so jata hai. Uske baad ki **pehli request 30-60 sec** leti hai (server jaagta hai). Ye normal hai — website pe loading dikhe to ghabrana nahi. 750 ghante/month free milte hain — akela personal use ke liye kaafi hai.

---

# Part 2 — Website: Vercel pe FREE deploy

### Step 2.1: Vercel account
1. https://vercel.com → **Sign Up → Continue with GitHub** (wahi GitHub se).

### Step 2.2: Project import karo
1. Dashboard → **Add New… → Project**
2. Apna repo `ShivaayMusic-main` **Import** karo.
3. Configure page pe:
   - **Framework Preset:** `Other`
   - **Root Directory:** `website`  ← **is pe EDIT karke `website` select karna na bhoole!**
   - Build command / output directory: **khaali chhodo** (plain static HTML hai)
4. **Deploy** dabao → 30 second me live!

### Step 2.3: URL mil gayi ✅
- Kuch aisi: `https://shivaaymusic-web.vercel.app`

> Vercel free hobby plan: unlimited static hosting + 100GB bandwidth/month. Website ke liye more than enough.

---

# Part 3 — Dono ko jodo (sabse aasan step)

1. Apni Vercel website kholo.
2. Upar right me **⚙️ (settings)** dabao.
3. **Server URL** me apna Render URL paste karo (jaisa `https://shivaaymusic-server.onrender.com` — aakhri me `/` mat lagana).
4. **Save**.
5. Search box me kuch bhi likho → results ▶ → **PLAY!** 🎉

*(Ye URL sirf tumhare browser ke localStorage me save hota hai — kisi ke saath share karo to unko apna set karna padega, ya website code me default bana do.)*

---

# 🩺 Troubleshooting

| Problem | Kyun hota hai | Fix |
|---|---|---|
| Search chal rahi par play nahi / 403 | YouTube ne stream URL ko server se alag IP pe rok diya | Website settings me **"Force proxy mode"** ON karo — bytes ab tumhare server se hoke aayenge (thoda slow, 100% chalega) |
| Pehli request 30-60 sec slow | Render free ka sleep mode | Normal hai; baad ki requests fast hoti hain |
| Render pe deploy fail | Root Directory `server` set nahi kiya | Settings → Build & Deploy → Root Directory = `server` |
| Vercel pe page blank | Root Directory `website` set nahi kiya | Settings → General → Root Directory = `website` → redeploy |
| `search failed` error aaya | YouTube ne server ki IP pe halki demand lagayi | Thodi der ruks ke try; server logs Render dashboard → Logs me dikhengi |
| Bandwidth khatam ho gayi (bahut saare users) | Proxy mode me server ka data use hota hai | Sirf khud ke liye rakho / proxy mode off rakho jab tak zaroori na ho |

---

# 🔒 Ek security tip (optional but smart)

Agar tumhe lagta hai koi aur tumhara free server use kar lega, to server me ek chhota secret daal sakte ho:
- Render dashboard → Environment → `API_KEY` = koi random string
- `server/bin/server.dart` me request check add karwa lo (main bana doon to bata dena)

---

# 🏠 Bonus: ghar ke PC pe server (0 rupee, sabse reliable)

YouTube datacenter IPs (Render/Oracle) ko kabhi-kabhi zyada pakadta hai. **Ghar ki IP sabse safe hai.**
1. PC pe Dart install karo → `cd server && dart pub get && dart run bin/server.dart`
2. Free **Cloudflare Tunnel** se expose karo:
   `cloudflared tunnel --url http://localhost:8080`
   → turant public `https://something.trycloudflare.com` URL milti hai (free, permanent banane ka option bhi hai)
3. Wo URL website settings me daal do. PC band ⇒ server band (bas itna hi catch).

---

**Koi step pe atko to batao — main usi jagah se help karunga!** 🚀
