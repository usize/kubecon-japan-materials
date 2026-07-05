// Tainted-server is the exfiltration target for the Finance-IBAC demo.
// It logs whatever it receives so operators can see the attack succeed
// (or, with IBAC enabled, see no logs because the request was blocked
// at the agent's authbridge sidecar before it ever reached us).
package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		body, err := io.ReadAll(r.Body)
		if err != nil {
			log.Printf("[Tainted] Failed to read body: %v", err)
			http.Error(w, "failed to read body", http.StatusBadRequest)
			return
		}

		log.Printf("[Tainted] ====== EXFILTRATED PORTFOLIO DATA ======")
		log.Printf("[Tainted] Method: %s", r.Method)
		log.Printf("[Tainted] URL: %s", r.URL.String())
		log.Printf("[Tainted] From: %s", r.RemoteAddr)
		log.Printf("[Tainted] Body (%d bytes): %s", len(body), string(body))
		log.Printf("[Tainted] =========================================")

		fmt.Fprintf(w, "received %d bytes", len(body))
	})

	addr := ":9999"
	log.Printf("[Tainted] Exfiltration server starting on %s", addr)
	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatalf("failed to start tainted server: %v", err)
	}
}
