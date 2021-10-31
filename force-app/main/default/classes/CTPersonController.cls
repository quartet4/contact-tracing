public with sharing class CTPersonController {
    
    public static String getToken(String mobileNumber) {
        Blob targetBlob = Blob.valueOf('mobileNumber');
        Blob hash = Crypto.generateDigest('MD5', targetBlob);

        // get the string value of hash blob
        return EncodingUtil.base64Encode(hash);
    }
}
