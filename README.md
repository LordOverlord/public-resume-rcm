# Rafael Camacho | Resume

This repository contains the LaTeX source code for my professional resume, based on the [AltaCV](https://github.com/liantze/AltaCV) template.

The resume is maintained in LaTeX and uses GitHub Actions to automate PDF generation and release management.

## Features

- **LaTeX-based resume:** Structured and customizable source code using AltaCV.
- **Professional layout:** Custom typography, category-colored skills, and linked certifications.
- **Automated builds:** PDF compilation using XeLaTeX and GitHub Actions.
- **Versioned releases:** Automated publishing of the latest resume and archival of previous PDF versions.
- **Source control:** Resume content, styling, and build configuration maintained in Git.

## Repository Structure

```text
.
├── .github/
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

- On pushes to `main` that modify `.tex`, `.png`, `.jpg`, or the workflow configuration.
- Through manual execution using `workflow_dispatch`.

### Build and Release Process

1. Check out the repository.
2. Compile `resume.tex` using XeLaTeX.
3. Rename the generated PDF to `resume.rafael.camacho.latest.pdf`.
4. Archive the previous published PDF as a numbered release (`v1`, `v2`, etc.), when applicable.
5. Upload the new PDF to the `latest` GitHub release.
6. Upload the generated PDF as a GitHub Actions artifact with a seven-day retention period.

The workflow currently publishes from `main`. Pull requests do not automatically trigger a validation build.

## Downloads

The workflow is configured to publish the most recent PDF through GitHub Releases.

**Latest resume:** [GitHub Releases](https://github.com/LordOverlord/public-resume-rcm/releases)

**Published filename:**

```text
resume.rafael.camacho.latest.pdf
```

Previous versions, when available, are retained under numbered releases.

## Contact

- **LinkedIn:** [linkedin.com/in/lordoverlord](https://www.linkedin.com/in/lordoverlord/)
- **GitHub:** [github.com/LordOverlord](https://github.com/LordOverlord)
- **Email:** overlordco@gmail.com
- **Location:** Mexico City, Mexico

## Credits

Based on [AltaCV](https://github.com/liantze/AltaCV), developed by LianTze Lim and contributors.
