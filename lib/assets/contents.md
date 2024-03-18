***Custom uploader is is a app that allows you to upload image/text/file to hosting services. This is useful for those who host their own hosting service, or for those that want to use some kind of other hosting service.***

# Form Data Name
Used to reference the form data in the request body.

# Upload Parameters
URL Parameters are a way pass information about a click through its URL. You can insert URL parameters into your URLs so that your URLs track information about a click. URL parameters are made of a key and a value separated by an equals sign (=) and joined by an ampersand (&). The first parameter always comes after a question mark in a URL. For example, the following URL contains two parameters: `https://example.com?param1=value1&param2=value2`.

# Upload Headers
HTTP Headers are a way to exchange additional information between the client and the server. Both in the request - the HTTP-Request - and in the server's response, some meta-information is exchanged in addition to the actual data. 

# Upload Arguments
Upload Arguments are used to pass data to the body of a request. Body arguments are passed in the body of the request and are used to send data to the server.
They take the form of a key-value pair, where the key is the name of the argument and the value is the value of the argument.

# Parsing Responses
The app Custom Uploader has a built-in URL response parser. This allows you to use the response from your upload service to get the finished URL of the uploaded file.
***
### response
If the response only contains file name (or id) and would like to append it to a domain, then you can use this syntax.
**Example:**
```
https://example.com/$json:response$
```
Or if the response contains a full URL, then you can use this syntax.

**Example:**
```
$json:response$
```
Notice how we use the `$json` syntax to get the JSON object from the response. Followed by the `:response`, and a `$` sign at the end to get the value property of the JSON object.

You can also combine multiple syntax's in the same url if the response is broken up into multiple parts. As an example, if the response is broken up into three parts, then you can use this syntax:
```
https://example.com/$json:response.hash$/$json:response.name$.$json:response.extension$
```
***

### json
You can use jsonPath to parse the url from a JSON response.

**Example response:**
```json
{
  "status": 200,
  "data": {
    "link": "https:\/\/example.com\/image.png"
  }
}
```
**Syntax:**
```
$json:data.link$
```
**Example response 2:**
```json
{
  "success": true,
  "files": [
    {
      "name": "image.png",
      "url": "https://example.com/image.png"
    }
  ]
}
```
**Syntax:**
```
$json:files[0].url$
```
***

### xml
You can use xmlPath to parse the url from a XML response.

**Example response:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<files>
    <file>
        <name>image.png</name>
        <url>https://example.com/image.png</url>
    </file>
  <file>
    <name>image2.png</name>
    <url>https://example.com/image2.png</url>
  </file>
</files>
```
**Syntax:**
```
$xml:files/file[0]/url$
```
***

### regex
You can use regex to parse the url from a response.

An `??` operator can also be used to separate multiple regexes.
As example: Use `??1` to get the first match.

**Example response:**
```
https://example.com/image.png
```
**Syntax:**
```
$regex:https:\/\/example.com\/(.*)??1$
```
***

### Note    
You can use the same method to parse the response from the error response.