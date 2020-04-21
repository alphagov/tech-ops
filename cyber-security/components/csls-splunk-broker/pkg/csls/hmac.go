package csls

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"errors"
)

var (
	ErrInvalidMessageAuthArgs = errors.New("invalid arguments for mac generation")
)

// GenerateMAC generates a base64 encoded Message Authentication Code for a
// given application GUID
func GenerateMAC(appGUID, serviceInstanceGUID, key string) (string, error) {
	if appGUID == "" || serviceInstanceGUID == "" || key == "" {
		return "", ErrInvalidMessageAuthArgs
	}
	mac := hmac.New(sha256.New, []byte(key))
	if _, err := mac.Write([]byte(appGUID)); err != nil {
		return "", err
	}
	if _, err := mac.Write([]byte(serviceInstanceGUID)); err != nil {
		return "", err
	}
	sig := mac.Sum(nil)
	return base64.StdEncoding.EncodeToString(sig), nil
}

// VerifyMAC checks that a given Message Authentication Code is valid for a
// given application GUID
func VerifyMAC(appGUID, serviceInstanceGUID, key, unverifiedMAC string) (bool, error) {
	// TODO: use a propper UUID type to avoid UUID string encoding issues
	if appGUID == "" || key == "" || unverifiedMAC == "" {
		return false, ErrInvalidMessageAuthArgs
	}
	expectedMAC, err := GenerateMAC(appGUID, serviceInstanceGUID, key)
	if err != nil {
		return false, err
	}
	return hmac.Equal([]byte(unverifiedMAC), []byte(expectedMAC)), nil
}
