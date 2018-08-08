package main

type ghost struct{}

func (g ghost) say() string {
	return "Boo!"
}

func (g ghost) show() string {
	return "\U0001f47b "
}
