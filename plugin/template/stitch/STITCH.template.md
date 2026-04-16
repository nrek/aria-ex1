# STITCH — {GROUP_ID}

> Cross-repo binding for this product group. Not narrative — tables only. Last verified: YYYY-MM-DD

## 1. Group identity

| Field | Value |
|-------|-------|
| Group | `{GROUP_ID}` |
| Backend repo | `{BACKEND}` @ `{BACKEND_SHA}` |
| Frontend repo(s) | `{FRONTENDS}` @ `{FE_SHA}` |
| CODEMAP paths | `{BACKEND}/CODEMAP.md`, … |

---

## 2. Auth stitch

| Step | Location | Notes |
|------|----------|-------|
| Login / token storage | FE file: … | … |
| Interceptor / refresh | FE file: … | … |
| Middleware / JWT | BE file: … | … |

*(Mermaid optional; keep minimal.)*

---

## 3. Endpoint stitch

| FE hook / client | HTTP | FE file | Path | BE urls module | View | Permission | Notes |
|------------------|------|---------|------|----------------|------|------------|-------|
| … | … | … | … | … | … | … | … |

---

## 4. Entity stitch

| Domain | FE type / schema | BE serializer | Model | Notes |
|--------|------------------|---------------|-------|-------|
| … | … | … | … | … |

---

## 5. Integration stitch

| Service | Env keys | Owner repo | Files |
|---------|----------|--------------|-------|
| … | … | backend | … |

---

## 6. Drift log

*(FE orphans / BE orphans — from `analyze_projects.py` or equivalent diff.)*

| Kind | Detail |
|------|--------|
| FE calls missing BE | … |
| BE routes unused by FE | … |
