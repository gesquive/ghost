package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"regexp"

	"github.com/spf13/cobra"
	"github.com/spf13/cobra/doc"
)

var destinationPath = "docs"

// docsCmd represents the docs command
var docsCmd = &cobra.Command{
	Use:    "docs",
	Short:  "Generate docs",
	Long:   `generate manpages`,
	Run:    runDocs,
	Hidden: true,
}

func init() {
	RootCmd.AddCommand(docsCmd)
}

func runDocs(cmd *cobra.Command, args []string) {
	generateManPages()
}

func generateManPages() {
	if _, err := os.Stat(destinationPath); os.IsNotExist(err) {
		os.MkdirAll(destinationPath, 0755)
	}

	header := &doc.GenManHeader{
		Title:   "GHOST",
		Section: "1",
		Source:  "ghost",
		Manual:  "ghost utils",
	}

	RootCmd.DisableAutoGenTag = true
	fmt.Printf("generating manpages for ghost\n")

	if err := doc.GenManTree(RootCmd, header, destinationPath); err != nil {
		fmt.Printf("%s\n", err)
		os.Exit(2)
	}

	//Remove all of the double blank lines from output docs
	err := filepath.Walk(destinationPath, func(path string, f os.FileInfo, err error) error {
		stripFile(path)
		return nil
	})

	if err != nil {
		fmt.Printf("Could not clean up all the files\n")
		fmt.Printf("%s", err)
	}
}

func stripFile(path string) error {
	input, err := ioutil.ReadFile(path)
	if err != nil {
		return err
	}

	regex, err := regexp.Compile("\n{2,}")
	if err != nil {
		return err
	}
	output := regex.ReplaceAllString(string(input), "\n")

	err = ioutil.WriteFile(path, []byte(output), 0644)
	if err != nil {
		return err
	}
	return nil
}
