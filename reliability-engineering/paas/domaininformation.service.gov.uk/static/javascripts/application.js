var tables = [].slice.apply(document.getElementsByClassName('clickable-table'));

tables.forEach(function(element) {
  var body = element.getElementsByTagName('tbody')[0]
    , rows = body.getElementsByTagName('tr')
    ;

  body.addEventListener('click', function(event) {
    var target = event.target
      , anchor;

    while (target && target != body) {
      if (target.nodeName == 'TR') {
        break;
      }
      target = target.parentElement;
    }

    if (target) {
      anchor = target.getElementsByTagName("a")[0]

      if (anchor && anchor.href) {
        window.location = anchor.href;
      }
    }
  });

  [].slice.apply(rows).forEach(function(row) {
    if (row.getElementsByTagName('a').length) {
      row.style.cursor = 'pointer';
    }
  });
});