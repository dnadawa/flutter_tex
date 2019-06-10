library flutter_tex;

import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mime/mime.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TeXView extends StatefulWidget {
  final int index;
  final Key key;
  final String teXHTML;
  final Function(double) onRenderFinished;
  final Function(String) onPageFinished;

  TeXView(
      {this.index = 0,
      this.key,
      this.teXHTML,
      this.onRenderFinished,
      this.onPageFinished});

  @override
  _TeXViewState createState() => _TeXViewState();
}

class _TeXViewState
    extends State<TeXView> /* with AutomaticKeepAliveClientMixin */ {
  _Server _server;
  int _port;
  double _height = 1;
  WebViewController _myController;
  String baseUrl;

/*  @override
  bool get wantKeepAlive => true;*/

  @override
  void initState() {
    _port = 8080 + widget.index;
    _server = _Server(port: _port);
    baseUrl = "http://localhost:$_port/packages/flutter_tex/MathJax/index.html";
    super.initState();
    serverCallbackHandler();
  }


  serverCallbackHandler() {
    _server.start((request) {
      double height = double.parse(request.uri.queryParameters['height']) + 15;
      if (_height == 1) {
        setState(() {
          this._height = height;
          if (widget.onRenderFinished != null) {
            widget.onRenderFinished(height);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    //super.build(context);

    return SizedBox(
      height: _height,
      child: WebView(
        key: widget.key,
        onWebViewCreated: (controller) {
          _myController = controller;
        },
        initialUrl:
            "$baseUrl?id=${Uri.encodeComponent(widget.index.toString())}&data=${Uri.encodeComponent(widget.teXHTML)}",
        onPageFinished: (message) {
          if (widget.onPageFinished != null) {
            widget.onPageFinished(message);
          }
          _myController.evaluateJavascript("""
        document.getElementById('data').innerHTML = decodeURIComponent(location.search.split('data=')[1]);
        
        MathJax.Hub.Queue(function () {
        var height = document.getElementById('data').clientHeight;
        var xmlHttp = new XMLHttpRequest();
        xmlHttp.open("GET", "http://localhost:$_port?rendering=completed&height="+height, true);
        xmlHttp.send(null);
        
        });
        """);
        },
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }

  @override
  void dispose() {
    _server.close();
    super.dispose();
  }
}

class _Server {
  // class from inAppBrowser

  HttpServer _server;

  int _port = 8080;

  _Server({int port = 8080}) {
    this._port = port;
  }

  ///Closes the server.
  Future<void> close() async {
    if (this._server != null) {
      await this._server.close(force: true);
      print('Server running on http://localhost:$_port closed');
      this._server = null;
    }
  }

  Future<void> start(Function onRenderFinished(HttpRequest request)) async {
    if (this._server != null) {
      throw Exception('Server already started on http://localhost:$_port');
    }

    var completer = new Completer();

    runZoned(() {
      HttpServer.bind('127.0.0.1', _port, shared: true).then((server) {
        print('Server running on http://localhost:' + _port.toString());

        this._server = server;

        server.listen((HttpRequest request) async {
          if (request.method == 'GET' &&
              request.uri.queryParameters['rendering'] == "completed") {
            onRenderFinished(request);
          }

          var body = List<int>();
          var path = request.requestedUri.path;
          path = (path.startsWith('/')) ? path.substring(1) : path;
          path += (path.endsWith('/')) ? 'index.html' : '';

          try {
            body = (await rootBundle.load(path)).buffer.asUint8List();
          } catch (e) {
            print(e.toString());
            request.response.close();
            return;
          }

          var contentType = ['text', 'html'];
          if (!request.requestedUri.path.endsWith('/') &&
              request.requestedUri.pathSegments.isNotEmpty) {
            var mimeType =
                lookupMimeType(request.requestedUri.path, headerBytes: body);
            if (mimeType != null) {
              contentType = mimeType.split('/');
            }
          }

          request.response.headers.contentType =
              new ContentType(contentType[0], contentType[1], charset: 'utf-8');
          request.response.add(body);
          request.response.close();
        });

        completer.complete();
      });
    }, onError: (e, stackTrace) => print('Error: $e $stackTrace'));

    return completer.future;
  }
}
