// Viewer-request router for themiscpage.com.
//
// The site is a static mirror of a 1999-2003 site whose forum pages were
// server-rendered CGI, addressed by query string. S3 can't vary on query
// strings, so archived CGI pages are stored under deterministic keys derived
// from (path, query) — the same transform tools/build_manifest.py used when
// the mirror was built. Keep the two in lockstep.
//
//   /forums/ubbcgi/ultimatebb.cgi?ubb=get_topic&f=1&t=000248
//     -> /forums/ubbcgi/ultimatebb.cgi__Q__ubb-get_topic__f-1__t-000248.html
//
// Anything the archive can't answer stays in character: non-GET methods get
// the UBB license page; missing objects fall through to the original IIS 404
// via the distribution's custom error response.

var LICENSE_PAGE = '/cgi-bin/error.html';

function redirect(location, code) {
  return {
    statusCode: code,
    statusDescription: code === 301 ? 'Moved Permanently' : 'Found',
    headers: { location: { value: location } }
  };
}

function transformQuery(qsObj) {
  var pairs = [];
  for (var key in qsObj) {
    var entry = qsObj[key];
    if (entry.multiValue) {
      for (var i = 0; i < entry.multiValue.length; i++) {
        pairs.push(key + '=' + entry.multiValue[i].value);
      }
    } else {
      pairs.push(key + '=' + entry.value);
    }
  }
  if (pairs.length === 0) return '';
  var q = pairs.join('&');
  // Mirror build_manifest.py local_path(): charset squash, then separator swaps.
  q = q.replace(/[^0-9A-Za-z=&+._-]/g, '~');
  q = q.replace(/&/g, '__').replace(/=/g, '-').replace(/\+/g, '_');
  return q;
}

function handler(event) {
  var request = event.request;
  var host = request.headers.host ? request.headers.host.value : '';
  var uri = request.uri;

  if (host === 'www.themiscpage.com') {
    return redirect('https://themiscpage.com' + uri, 301);
  }

  if (request.method !== 'GET' && request.method !== 'HEAD') {
    // Sorry! An error has occurred. (The license could not be renewed.)
    return redirect(LICENSE_PAGE, 302);
  }

  if (uri.endsWith('/')) {
    request.uri = uri + 'index.html';
    request.querystring = {};
    return request;
  }

  var isCgi = uri.endsWith('.cgi') || uri.endsWith('.php');
  if (isCgi) {
    var q = transformQuery(request.querystring);
    if (q !== '') {
      var key = uri + '__Q__' + q;
      if (key.slice(-5) !== '.html') key += '.html';
      request.uri = key;
    }
    request.querystring = {};
    return request;
  }

  request.querystring = {};
  return request;
}
