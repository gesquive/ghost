package main

import (
	"fmt"
	"os"
	"runtime"
	"strings"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

// current build info
var (
	BuildVersion = "v1.0.6-dev"
	BuildCommit  = ""
	BuildDate    = ""
)

var cfgFile string

var showVersion bool

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
		RootCmd.HelpTemplate(), BuildVersion))
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

	RootCmd.PersistentFlags().BoolP("run-once", "o", false,
		"Only run once and exit")

	viper.SetEnvPrefix("ghost")
	viper.AutomaticEnv()
	viper.BindEnv("config")
	viper.BindEnv("run-once")

	viper.BindPFlag("config", RootCmd.PersistentFlags().Lookup("config"))
	viper.BindPFlag("run_once", RootCmd.PersistentFlags().Lookup("run-once"))

}

// initConfig reads in config file and ENV variables if set.
func initConfig() {
	cfgFile := viper.GetString("config")
	if cfgFile != "" { // enable ability to specify config file via flag
		viper.SetConfigFile(cfgFile)
	} else {
		viper.SetConfigName("config")              // name of config file (without extension)
		viper.AddConfigPath(".")                   // add current directory as first search path
		viper.AddConfigPath("$HOME/.config/ghost") // add home directory to search path
		viper.AddConfigPath("/etc/ghost")          // add etc to search path
	}

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
		fmt.Printf("github.com/gesquive/ghost\n")
		fmt.Printf("  Version:    %s\n", BuildVersion)
		if len(BuildCommit) > 6 {
			fmt.Printf("  Git Commit: %s\n", BuildCommit[:7])
		}
		if BuildDate != "" {
			fmt.Printf("  Build Date: %s\n", BuildDate)
		}
		fmt.Printf("  Go Version: %s\n", runtime.Version())
		fmt.Printf("  OS/Arch:    %s/%s\n", runtime.GOOS, runtime.GOARCH)
		os.Exit(0)
	}
}

func run(cmd *cobra.Command, args []string) {
	var g ghost
	if viper.GetBool("run_once") {
		g.Boo()
	} else {
		g.Hunt(15)
	}
}
