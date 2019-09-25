package main

import (
	"fmt"
	"os"
	"runtime"
	"strings"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var (
	buildVersion = "v1.0.4-dev"
	buildCommit  = ""
	buildDate    = ""
)

var cfgFile string

var showVersion bool

func main() {
	Execute()
}

// RootCmd represents the base command when called without any subcommands
var RootCmd = &cobra.Command{
	Use:   "ghost",
	Short: "This app is transient and does nothing",
	Long: `This app is transient and does nothing, all you see is the faint 
outline of an application`,
	PreRun: preRun,
	Run:    run,
}

// Execute adds all child commands to the root command sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	RootCmd.SetHelpTemplate(fmt.Sprintf("%s\nVersion:\n  github.com/gesquive/ghost %s\n",
		RootCmd.HelpTemplate(), buildVersion))
	if err := RootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(-1)
	}
}

func init() {
	cobra.OnInitialize(initConfig)

	RootCmd.PersistentFlags().StringVar(&cfgFile, "config", "",
		"Path to a specific config file (default \"./config.yml\")")

	RootCmd.PersistentFlags().BoolVar(&showVersion, "version", false,
		"Display the version number and exit")

}

// initConfig reads in config file and ENV variables if set.
func initConfig() {
	if cfgFile != "" { // enable ability to specify config file via flag
		viper.SetConfigFile(cfgFile)
	}

	viper.SetConfigName("config")              // name of config file (without extension)
	viper.AddConfigPath(".")                   // add current directory as first search path
	viper.AddConfigPath("$HOME/.config/ghost") // add home directory to search path
	viper.AddConfigPath("/etc/ghost")          // add etc to search path
	viper.AutomaticEnv()                       // read in environment variables that match

	// If a config file is found, read it in.
	if err := viper.ReadInConfig(); err != nil {
		if !showVersion {
			if !strings.Contains(err.Error(), "Not Found") {
				fmt.Printf("Error opening config: %s\n", err)
			}
		}
	}
}

func preRun(cmd *cobra.Command, args []string) {
	if showVersion {
		fmt.Printf("Version:   %s\n", buildVersion)
		if len(buildCommit) > 6 {
			fmt.Printf("Commit:    %s\n", buildCommit[:7])
		}
		if buildDate != "" {
			fmt.Printf("BuildDate: %s\n", buildDate)
		}
		fmt.Printf("Compiler:  %s\n", runtime.Version())
		os.Exit(0)
	}
}

func run(cmd *cobra.Command, args []string) {
	var g ghost
	fmt.Println(g.show(), g.say())
}
