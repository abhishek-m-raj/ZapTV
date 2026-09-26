package main

/*
#include <stdlib.h>
*/
import "C"

import (
	"fmt"
	"log"
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
	initOnce  sync.Once
	initErr   error
	goDataDir string // stored data directory for deferred initialization
)

func init() {
	// Initialize utils.Log early to prevent nil pointer dereferences
	utils.Log = log.New(os.Stdout, "[JioTV Go] ", log.LstdFlags)
}

// ensureInitialized guarantees that config, logger, store, and secureurl
// are set up exactly once, regardless of whether the caller is
// JioTVGoStartServer or one of the OTP helpers.
func ensureInitialized(dataDir string) error {
	// Prefer explicit dataDir, fall back to previously stored one.
	if dataDir != "" {
		goDataDir = dataDir
	}
	initOnce.Do(func() {
		if goDataDir != "" {
			if err := os.Chdir(goDataDir); err != nil {
				initErr = fmt.Errorf("failed to chdir to %s: %w", goDataDir, err)
				return
			}
			// Set JIOTV_PATH_PREFIX so GetPathPrefix() uses our app data
			// directory instead of os.UserHomeDir() (which is /sdcard on Android
			// and not writable).
			os.Setenv("JIOTV_PATH_PREFIX", goDataDir)
		}

		if err := cmd.LoadConfig(""); err != nil {
			initErr = fmt.Errorf("failed to load config: %w", err)
			return
		}

		cmd.InitializeLogger()

		if err := store.Init(); err != nil {
			initErr = fmt.Errorf("failed to init store: %w", err)
			return
		}

		secureurl.Init()
	})
	return initErr
}

//export JioTVGoSetDataDir
func JioTVGoSetDataDir(dataDir *C.char) {
	if dataDir != nil {
		goDataDir = C.GoString(dataDir)
	}
}

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

	localDataDir := ""
	if dataDir != nil {
		localDataDir = C.GoString(dataDir)
	}

	if err := ensureInitialized(localDataDir); err != nil {
		setLastError(err)
		return -1
	}

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

	// Ensure Go subsystems (store, config, etc.) are initialized
	if err := ensureInitialized(""); err != nil {
		setLastError(fmt.Errorf("init failed before sendOTP: %w", err))
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

	// Ensure Go subsystems (store, config, etc.) are initialized
	if err := ensureInitialized(""); err != nil {
		setLastError(fmt.Errorf("init failed before verifyOTP: %w", err))
		return -1
	}

	num := C.GoString(number)
	if !strings.HasPrefix(num, "+") {
		num = "+91" + num
	}
	goOtp := C.GoString(otp)
	res, err := utils.LoginVerifyOTP(num, goOtp)
	if err != nil {
		setLastError(fmt.Errorf("verify OTP failed: %v", err))
		return -1
	}
	if len(res) == 0 {
		setLastError(fmt.Errorf("verify OTP failed: empty credentials returned"))
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

