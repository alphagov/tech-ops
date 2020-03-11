package csls

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
)

// GenerateMAC generates a base64 encoded Message Authentication Code for a
// given application GUID
func GenerateMAC(appGUID, key string) (string, error) {
	mac := hmac.New(sha256.New, []byte(key))
	_, err := mac.Write([]byte(appGUID))
	if err != nil {
		return "", err
	}
	sig := mac.Sum(nil)
	return base64.StdEncoding.EncodeToString(sig), nil
}

// VerifyMAC checks that a given Message Authentication Code is valid for a
// given application GUID
func VerifyMAC(appGUID, key, unverifiedMAC string) (bool, error) {
	// TODO: use a propper UUID type to avoid UUID string encoding issues
	if appGUID == "" || key == "" || unverifiedMAC == "" {
		return false, nil
	}
	expectedMAC, err := GenerateMAC(appGUID, key)
	if err != nil {
		return false, err
	}
	return hmac.Equal([]byte(unverifiedMAC), []byte(expectedMAC)), nil
}
