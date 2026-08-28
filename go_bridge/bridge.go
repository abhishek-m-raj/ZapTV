package main

/*
#include <stdlib.h>
*/
import "C"

import (
	"fmt"
	"os"
	"strings"
	"sync"
	"sync/atomic"
	"unsafe"

	"github.com/jiotv-go/jiotv_go/v3/cmd"
	"github.com/jiotv-go/jiotv_go/v3/pkg/secureurl"
	"github.com/jiotv-go/jiotv_go/v3/pkg/store"
	"github.com/jiotv-go/jiotv_go/v3/pkg/utils"
)

var (
	mu        sync.Mutex
	isRunning atomic.Bool
	lastError string
)

func setLastError(err error) {
	if err != nil {
		mu.Lock()
		lastError = err.Error()
		mu.Unlock()
	}
}

//export JioTVGoStartServer
func JioTVGoStartServer(port *C.char, dataDir *C.char) C.int {
	mu.Lock()
	if isRunning.Load() {
		mu.Unlock()
		return 0 // Already running
	}
	mu.Unlock()

	goPort := "5001"
	if port != nil {
		p := C.GoString(port)
		if p != "" {
			goPort = p
		}
	}

	if dataDir != nil {
		dir := C.GoString(dataDir)
		if dir != "" {
			if err := os.Chdir(dir); err != nil {
				setLastError(fmt.Errorf("failed to chdir to %s: %w", dir, err))
				return -1
			}
		}
	}

	// Init components
	err := cmd.LoadConfig("")
	if err != nil {
		setLastError(fmt.Errorf("failed to load config: %w", err))
		return -1
	}

	cmd.InitializeLogger()

	if err := store.Init(); err != nil {
		setLastError(fmt.Errorf("failed to init store: %w", err))
		return -1
	}

	secureurl.Init()

	config := cmd.JioTVServerConfig{
		Host: "0.0.0.0",
		Port: goPort,
	}

	isRunning.Store(true)

	go func() {
		defer isRunning.Store(false)
		if err := cmd.JioTVServer(config); err != nil {
			setLastError(fmt.Errorf("server error: %w", err))
		}
	}()

	return 0
}

//export JioTVGoStopServer
func JioTVGoStopServer() {
	isRunning.Store(false)
}

//export JioTVGoIsRunning
func JioTVGoIsRunning() C.int {
	if isRunning.Load() {
		return 1
	}
	return 0
}

//export JioTVGoSendOTP
func JioTVGoSendOTP(number *C.char) C.int {
	if number == nil {
		setLastError(fmt.Errorf("mobile number is required"))
		return -1
	}
	num := C.GoString(number)
	if !strings.HasPrefix(num, "+") {
		num = "+91" + num
	}
	ok, err := utils.LoginSendOTP(num)
	if err != nil || !ok {
		setLastError(fmt.Errorf("send OTP failed: %v", err))
		return -1
	}
	return 0
}

//export JioTVGoVerifyOTP
func JioTVGoVerifyOTP(number *C.char, otp *C.char) C.int {
	if number == nil || otp == nil {
		setLastError(fmt.Errorf("number and OTP are required"))
		return -1
	}
	num := C.GoString(number)
	if !strings.HasPrefix(num, "+") {
		num = "+91" + num
	}
	goOtp := C.GoString(otp)
	ok, err := utils.LoginVerifyOTP(num, goOtp)
	if err != nil || !ok {
		setLastError(fmt.Errorf("verify OTP failed: %v", err))
		return -1
	}
	return 0
}

//export JioTVGoGetLastError
func JioTVGoGetLastError() *C.char {
	mu.Lock()
	defer mu.Unlock()
	if lastError == "" {
		return nil
	}
	return C.CString(lastError)
}

//export JioTVGoFreeString
func JioTVGoFreeString(str *C.char) {
	if str != nil {
		C.free(unsafe.Pointer(str))
	}
}

func main() {}
