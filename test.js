var hasKey, item, j, len, menu, namespace, tree;

menu = [
  {
    name: 'index.html',
    path: 'menu/index.html',
    parent: 'menu'
  }, {
    name: 'info.md',
    path: 'menu/info.md',
    parent: 'menu'
  }, {
    name: 'other.md',
    path: 'menu/other.md',
    parent: 'menu'
  }, {
    name: 'aboutsubmenu.md',
    path: 'menu/submenu/aboutsubmenu.md',
    parent: 'menu/submenu'
  }, {
    name: 'aboutagain.md',
    path: 'menu/submenu/nextsubmenu/aboutagain.md',
    parent: 'menu/submenu/nextsubmenu'
  }
];

tree = [
  {
    menu: [
      'index', 'info', 'bla', {
        submenu: []
      }
    ]
  }
];

hasKey = function(ob, key) {
  var i, j, len;
  for (j = 0, len = ob.length; j < len; j++) {
    i = ob[j];
    if (i.hasOwnProperty(key)) {
      return i;
    }
  }
  return false;
};

namespace = function(base, string, end) {
  var index, j, key, len, parts, res, tmp;
  parts = string.split('/');
  for (index = j = 0, len = parts.length; j < len; index = ++j) {
    key = parts[index];
    res = hasKey(base, key);
    if (!res) {
      tmp = {};
      tmp[key] = [];
      base.push(tmp);
      base = tmp;
    } else {
      base = res;
    }
  }
  return base.push(end);
};

for (j = 0, len = menu.length; j < len; j++) {
  item = menu[j];
  namespace(tree, item.parent, item.path);
}

console.log(tree);