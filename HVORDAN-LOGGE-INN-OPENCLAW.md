# 🚀 Slik logger du inn på OpenClaw

**Oppdatert:** 2. februar 2026

---

## Daglig rutine (morgen)

### Steg 1: Åpne VS Code
Bare start VS Code på PC-en din.

### Steg 2: Koble til EC2-serveren
1. Trykk `Ctrl+Shift+P` (eller `F1`)
2. Skriv: **Remote-SSH: Connect to Host**
3. Velg: **openclaw-ec2**
4. Nytt vindu åpnes
5. Vent til "SSH: openclaw-ec2" vises nederst til venstre ✅

### Steg 3: Sjekk at port er forwarded
1. Se nederst i VS Code vinduet → finner du **"PORTS"**-fanen
2. Sjekk at **18789** står der
3. Hvis ikke: Klikk "Forward a Port" → skriv **18789** → Enter

### Steg 4: Åpne OpenClaw i nettleseren
Åpne denne URL-en (favorittmerk den!):

```
http://localhost:18789/?token=8fcf852f094fe3a03974d722d35d2fabf3acf8393945b442
```

**Du er inne!** 🎉

---

## Første gang oppsett (allerede gjort)

✅ VS Code Remote SSH extension installert
✅ SSH config lagt til (`~/.ssh/config`):
```
Host openclaw-ec2
    HostName 51.20.42.117
    User ubuntu
    IdentityFile C:\Users\GlennHåvarBrottveit\Downloads\AI\OpenClawd\ghb.pem
```

---

## Hvis noe ikke virker

### Problem: "Connection refused" eller timeout
**Løsning:** EC2-serveren er kanskje av. Sjekk AWS Console.

### Problem: "Unauthorized: gateway token missing"
**Løsning:** Bruk URL-en med token (se Steg 4).

### Problem: Port 18789 vises ikke i PORTS
**Løsning:** 
1. Trykk `Ctrl+Shift+P`
2. "Forward a Port"
3. Skriv **18789**

### Problem: VS Code spør om passord
**Løsning:** Sjekk at nøkkelfilen (`ghb.pem`) ligger i riktig mappe.

---

## Nyttige kommandoer (i VS Code terminal)

```bash
openclaw status              # Sjekk status
openclaw gateway logs        # Se logger
openclaw chat                # Chat i terminal
openclaw dashboard           # Få ny dashboard URL
```

---

## Kontaktinfo

- **EC2 IP:** 51.20.42.117
- **SSH User:** ubuntu
- **Gateway Port:** 18789
- **SSH Key:** `C:\Users\GlennHåvarBrottveit\Downloads\AI\OpenClawd\ghb.pem`

---

_Laget av Nikoline 🤖_
