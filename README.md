# murkel
Generate static site from markdown files

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
│   
scaffolding
│   page.html
│   header.html
│   body.html
│   footer.html

```

Run the cli.coffee with coffeescript from the root folder. A folder named `static_site` will be created containing the same structure as `pages` but compiled by the templates in `scaffolding`. `assets` will also be copied over to `static_site` folder.

Add `---` JSON `---` to specify data that will be available in the views.
For the example:
```
---
"title": "Some title"
---
```
the title property is set in every file, and is then printed out in the menu.

