package csls

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"errors"

	uuid "github.com/satori/go.uuid"
)

var (
	ErrInvalidMessageAuthArgs = errors.New("invalid arguments for mac generation")
)

// GenerateMAC generates a base64 encoded Message Authentication Code for a
// given application GUID
func GenerateMAC(appGUID, serviceInstanceGUID uuid.UUID, key string) (string, error) {
	if uuid.Equal(appGUID, uuid.Nil) {
		return "", ErrInvalidMessageAuthArgs
	}
	if uuid.Equal(serviceInstanceGUID, uuid.Nil) {
		return "", ErrInvalidMessageAuthArgs
	}
	if key == "" {
		return "", ErrInvalidMessageAuthArgs
	}
	mac := hmac.New(sha256.New, []byte(key))
	if _, err := mac.Write(appGUID.Bytes()); err != nil {
		return "", err
	}
	if _, err := mac.Write(serviceInstanceGUID.Bytes()); err != nil {
		return "", err
	}
	sig := mac.Sum(nil)
	return base64.StdEncoding.EncodeToString(sig), nil
}

// VerifyMAC checks that a given Message Authentication Code is valid for a
// given application GUID
func VerifyMAC(appGUID, serviceInstanceGUID uuid.UUID, key, unverifiedMAC string) (bool, error) {
	if uuid.Equal(appGUID, uuid.Nil) {
		return false, ErrInvalidMessageAuthArgs
	}
	if uuid.Equal(serviceInstanceGUID, uuid.Nil) {
		return false, ErrInvalidMessageAuthArgs
	}
	if key == "" || unverifiedMAC == "" {
		return false, ErrInvalidMessageAuthArgs
	}
	expectedMAC, err := GenerateMAC(appGUID, serviceInstanceGUID, key)
	if err != nil {
		return false, err
	}
	return hmac.Equal([]byte(unverifiedMAC), []byte(expectedMAC)), nil
}
