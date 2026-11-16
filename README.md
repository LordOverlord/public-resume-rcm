# Rafael Camacho | Resume

This repository contains the LaTeX source code for my professional resume, based on the [AltaCV](https://github.com/liantze/AltaCV) template.

The resume is maintained in LaTeX and uses GitHub Actions to automate PDF generation and release management.

## Features

- **LaTeX-based resume:** Structured and customizable source code using AltaCV.
- **Professional layout:** Custom typography, category-colored skills, and linked certifications.
- **Automated builds:** PDF compilation and pull request validation using XeLaTeX and GitHub Actions.
- **Versioned releases:** Each successful publication from `main` creates a timestamped release (`YYYYMMDDHHMM`, Mexico City time) linked to its source commit, while older releases remain available.
- **Source control:** Resume content, styling, and build configuration maintained in Git.

## Repository Structure

```text
.
├── .github/
│   ├── scripts/
│   │   └── publish-resume.sh
│   └── workflows/
│       └── build-resume.yaml
├── .gitignore
├── altacv.cls
├── avatar.jpg
├── leftovers.txt
├── README.md
└── resume.tex
```

| File | Description |
|---|---|
| `resume.tex` | Main resume content and styling |
| `altacv.cls` | AltaCV document class |
| `avatar.jpg` | Profile image used in the resume |
| `leftovers.txt` | Historical LaTeX snippets retained for reference |
| `.github/workflows/build-resume.yaml` | Automated PDF build and release workflow |
| `.github/scripts/publish-resume.sh` | Release publishing by ID, dated tags and legacy draft recovery |
| `.gitignore` | Excludes generated LaTeX files and PDFs from version control |

## Local Compilation

### Requirements

- A TeX Live installation with XeLaTeX
- `latexmk`
- Required LaTeX packages and fonts used by AltaCV

### Build

Run the following command from the repository root:

```bash
latexmk -xelatex -interaction=nonstopmode -halt-on-error resume.tex
```

The generated PDF will be available as:

```text
resume.pdf
```

To remove auxiliary build files:

```bash
latexmk -c
```

## GitHub Actions

The workflow is defined in:

```text
.github/workflows/build-resume.yaml
```

### Build Triggers

The workflow is configured to execute:

- On pull requests targeting `main` (validation only; no release is published).
- On pushes to `main` that change `.tex`, `.cls`, images (`.png`, `.jpg`, `.jpeg`), fonts (`.ttf`, `.otf`), the workflow configuration, or the publisher script.
- Through manual execution using `workflow_dispatch` (publishing is restricted to runs from `main`).

### Build and Release Process

1. **Build:** Check out the repository and compile `resume.tex` with XeLaTeX using TeX Live 2024.
2. Verify that `resume.pdf` exists and is a valid, nonempty PDF.
3. Validate essential ATS-readable text, page count, and release script syntax; upload the PDF as a seven-day GitHub Actions artifact.
4. **Publish:** For eligible runs from `main` only, download the validated artifact without recompiling.
5. Create or resume a draft release by its numeric release ID, targeting the exact source commit. Use the Mexico City publication timestamp (`YYYYMMDDHHMM`) as the release tag.
6. Upload and verify two assets: a stable `latest` filename and a timestamped PDF. Publish the completed draft as GitHub's Latest release without changing previously published versions.
7. For the original interrupted `v1` draft, recover its existing PDF and timestamp as a historical release without rebuilding it.

Pull requests run only the read-only build job. Release publication uses write permissions exclusively in the publishing job. A rerun of an already-published source commit does not create a second version.

## Downloads

The workflow is configured to publish the most recent PDF through a versioned GitHub Release marked as Latest. The stable download URL refers to the latest published version:

**Latest resume:** [GitHub Releases](https://github.com/LordOverlord/public-resume-rcm/releases/latest)

**Direct PDF:** [resume.rafael.camacho.latest.pdf](https://github.com/LordOverlord/public-resume-rcm/releases/latest/download/resume.rafael.camacho.latest.pdf)

**Files attached to a new release:**

```text
resume.rafael.camacho.latest.pdf
resume.rafael.camacho.YYYYMMDDHHMM.pdf
```

The dated filename is unique per publication minute in the `America/Mexico_City` timezone. Publishing the same source commit again is idempotent; if a different commit uses the same minute, the job waits until a free minute. The historical `v1` draft is migrated to its original timestamp with its already-uploaded PDF, not regenerated.

## Contact

- **LinkedIn:** [linkedin.com/in/lordoverlord](https://www.linkedin.com/in/lordoverlord/)
- **GitHub:** [github.com/LordOverlord](https://github.com/LordOverlord)
- **Email:** overlordco@gmail.com
- **Location:** Mexico City, Mexico

## Credits

Based on [AltaCV](https://github.com/liantze/AltaCV), developed by LianTze Lim and contributors.
