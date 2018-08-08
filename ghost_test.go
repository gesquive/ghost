package main

import "testing"

//TestGhost tests
func TestGhost(t *testing.T) {
	var g ghost
	if g.show() != "\U0001f47b " {
		t.Error("ghost has changed")
	}
}
