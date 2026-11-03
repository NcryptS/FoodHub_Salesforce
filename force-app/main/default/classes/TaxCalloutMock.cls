@isTest
public class TaxCalloutMock implements HttpCalloutMock {
  private Integer statusCode;
  private String responseBody;

  public TaxCalloutMock(Integer statusCode, String responseBody) {
    this.statusCode = statusCode;
    this.responseBody = responseBody;
  }

  public HTTPResponse respond(HTTPRequest req) {
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'application/json');
    res.setStatusCode(this.statusCode);
    res.setBody(this.responseBody);
    return res;
  }
}
