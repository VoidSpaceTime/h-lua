package cmd

import (
	"fmt"
)

func Help() {
	fmt.Println("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	fmt.Println("┃ *:required")
	fmt.Println("┃ ~:optional")
	fmt.Println("┃ sdk.exe new [:PROJECT_NAME] - new a project")
	fmt.Println("┃ sdk.exe we [:PROJECT_NAME] - open map by YDWE")
	fmt.Println("┃ sdk.exe model [*PROJECT_NAME] [~CURRENT_PAGE:0] - view models, 289 in a page")
	fmt.Println("┃ sdk.exe clear [:PROJECT_NAME] - clear temp")
	fmt.Println("┃ sdk.exe multi [:QUANTITY] - open War3 client")
	fmt.Println("┃ sdk.exe kill - Try to close all War3 client")
	fmt.Println("┃ sdk.exe test [:PROJECT_NAME] - test a project")
	fmt.Println("┃ sdk.exe build [:PROJECT_NAME] - package a project for pre launch")
	fmt.Println("┃ sdk.exe dist [:PROJECT_NAME] - package a project for launch")
	fmt.Println("┃")
	fmt.Println("┃ @see https://h-lua.hunzsig.org")
	fmt.Println("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
}
