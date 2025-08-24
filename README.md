# 📄 Resume - Rafael Camacho

Este repositorio contiene mi CV en formato **LaTeX** (basado en [AltaCV](https://github.com/liantze/AltaCV)) con integración a **GitHub Actions** para generar automáticamente la última versión en PDF.

---

## 🚀 Características
- 📌 Redacción y formato en **LaTeX**
- 🎨 Iconografía con **FontAwesome 5** y **Academicons**
- ⚙️ Workflow de **GitHub Actions** para compilar y publicar el PDF como artefacto
- 🏷️ Manejo automático de versiones:
  - El build más reciente se publica como **latest**
  - Builds anteriores son renombrados con un tag de versión (`v1`, `v2`, etc.)

---

## 📂 Estructura del repo

```bash
.
├── resume.tex # Archivo principal del CV
├── resume.cls / altacv.cls # Plantilla usada (AltaCV)
├── .github/
│ └── workflows/
│ └── build.yml # Pipeline de GitHub Actions
├── .gitignore # Archivos temporales de LaTeX
└── README.md # Este archivo
```

---

## ⚡ Uso local

### Requisitos
- [TeX Live](https://www.tug.org/texlive/) o [MikTeX](https://miktex.org/)
- `latexmk` y paquetes estándar de LaTeX

### Compilación

latexmk -pdf resume.tex

El PDF resultante se genera como:

resume.rafael.camacho.latest.pdf

## 📬 Contacto
- 🌐 [LinkedIn](https://www.linkedin.com/in/lordoverlord/)  
- 📧 [overlordco@gmail.com](mailto:overlordco@gmail.com)  
- 📍 CDMX, México