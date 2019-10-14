package main

import (
	"fmt"
	"math/rand"
	"time"
)

type ghost struct{}

func (g ghost) say() string {
	return "Boo!"
}

func (g ghost) show() string {
	return "\U0001f47b "
}

func (g ghost) Boo() {
	fmt.Println(g.say(), g.show())
}

// RunHunt runs as a continuous service
func (g ghost) Hunt(maxReveal int) {
	for {
		go g.Boo()
		time.Sleep(time.Duration(rand.Intn(maxReveal)) * time.Second)
	}
}
