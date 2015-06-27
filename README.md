# murkel
Generates static site from markdown files

## Folder Structure

```
assets
│   main.css
│   main.js
│   
pages
│   404.html
│   index.md
│   
└───menu
    │   about.md
    │   contact.md
    │
    ├───submenu
    │   │   about-submenu.md
    │   │   information.md
    │   │   ...
    │   
scaffolding
│   page.html
│   header.html
│   body.html
│   footer.html

```

Run the cli.coffee with coffeescript from the root folder. A folder named `static_site` will be created containing the same structure as `pages` but compiled by the templates in `scaffolding`.