package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

func main() {
	ctx := context.Background()

	port := os.Getenv("PORT")

	if port == "" {
		port = "5555"
	}

	router := chi.NewRouter()

	router.Use(middleware.Logger)
	router.Use(middleware.Heartbeat("/health"))

	httpServer := &http.Server{
		Addr:    fmt.Sprintf(":%s", port),
		Handler: router,
	}

	router.Get("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello, World!")
	})

	log.Printf("Starting server on port %s\n", port)

	go func() {
		httpServer.ListenAndServe()
	}()

	// Create a channel to listen for shutdown signals
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan,
		syscall.SIGINT,  // Interrupt (Ctrl+C)
		syscall.SIGTERM, // Termination
		syscall.SIGHUP,  // Hangup
		syscall.SIGQUIT, // Quit
		syscall.SIGABRT, // Abort
	)

	// Block until a signal is received
	sig := <-sigChan

	err := httpServer.Shutdown(ctx)

	if err != nil {
		log.Printf("Error during server shutdown: %v\n", err)
		os.Exit(1)
	}

	log.Printf("Received signal: %s. Shutting down gracefully...\n", sig)
	os.Exit(0)
}
