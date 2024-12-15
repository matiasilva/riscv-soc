# Configuration file for the Sphinx documentation builder.

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = "Minimal RISC-V SoC"
copyright = "2024, Matias Wang Silva"
author = "Matias Wang Silva"

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = ["myst_parser", "sphinx_last_updated_by_git"]

templates_path = ["_templates"]
exclude_patterns = ["build", "Thumbs.db", ".DS_Store"]

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = "furo"
html_static_path = ["_static"]
html_theme_options = {
    "source_edit_link": "https://github.com/matiasilva/riscv-soc/edit/master/docs/src/{filename}",
    "source_view_link": "https://github.com/matiasilva/riscv-soc/blob/master/docs/src/{filename}",
}

myst_number_code_blocks = ["C", "python", "yaml"]
myst_links_external_new_tab = True
myst_heading_anchors = 3

# LaTeX output
latex_engine = "lualatex"
