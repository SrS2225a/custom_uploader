# Custom Uploader Documentation

The **Custom Uploader** app allows users to upload images, text, or files to hosting services. It is ideal for those hosting their own services or using third-party hosting platforms.

---

## **Form Data Name**
The **Form Data Name** specifies the key used to reference the form data in the request body. This is required by many APIs to identify uploaded content.

---

## **Upload Parameters**
**URL Parameters** are used to pass information via the URL in a key-value format.  
- The key and value are separated by an equals sign (`=`).  
- Multiple parameters are joined by an ampersand (`&`).  
- The first parameter in a URL always follows a question mark (`?`).

**Example:**
```https://example.com?param1=value1&param2=value2```

Here, `param1` and `param2` are the keys, and `value1` and `value2` are their respective values.

---

## **Upload Headers**
**HTTP Headers** are used to pass additional information between the client and server during an upload.
Headers can:
- Define the type of content being sent (e.g., Content-Type: application/json).
- Specify authentication details (e.g., Authorization: Bearer <token>).
- Control caching, security, and other communication settings.

**Example:**
```
Content-Type: application/json  
Authorization: Bearer abc123xyz
```

Headers are commonly used for specifying how data should be processed or for security-related information.

---

## **Upload Arguments**
**Upload Arguments** are used to pass data within the body of a request.  
They are sent as key-value pairs, where:
- **Key**: Name of the argument.
- **Value**: The data being sent.

These arguments are typically used for API requests that require additional data alongside the file being uploaded.

---

## **Parsing Responses**
The **Custom Uploader** app includes a response parser that helps extract the finished URL or relevant details from the response. This is useful for handling services that return complex responses.

### **Automatic URL Extraction**
If you don't specify a parsing syntax, the parser will automatically attempt to extract a URL using a built-in regular expression.  
**Example Response:**
``https://example.com/image.png``

**Automatic Parsing Result:**
``https://example.com/image.png``

### **Basic Response Parsing**
- If the response contains **only the file name or ID**, you can append it to a base domain using this syntax: ``https://example.com/$json:response$``
- If the response contains a **full URL**, simply use: ``$json:response$``

**Combining Multiple Parts**  
For responses with multiple parts, you can combine them into a full URL.  
**Example Syntax:**
``https://example.com/$json:response.hash$/$json:response.name$.$json:response.extension$``


---

### **JSON Parsing**
Use JSON paths to extract data from JSON responses.

**Example 1:**  
**Response:**
```json
{
  "status": 200,
  "data": {
    "link": "https://example.com/image.png"
  }
}
```
**Syntax:**
```ruby
$json:data.link$
```

**Example 2:**
**Response:**
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
```ruby
$json:files[0].url$
```

---

### XML Parsing
Use XML paths to extract data from XML responses.

**Example Response**
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
```ruby
$xml:files/file[0]/url$
```

---

### Regex Parsing
Use regular expressions (regex) to extract data from responses.
  - Use the `??` operator to handle multiple matches.
  - Specify a match position using `??1`, `??2`, etc.

**Example Response**
```arduino
https://example.com/image.png
```
**Syntax:**
```ruby
$regex:https:\/\/example.com\/(.*)??1$
```

---

## Note
The same parsing methods can also be applied to error responses to extract error-specific information.
