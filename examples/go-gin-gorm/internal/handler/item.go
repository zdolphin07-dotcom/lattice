package handler

import "github.com/gin-gonic/gin"

func RegisterItemRoutes(r *gin.RouterGroup) {
	r.POST("/items", CreateItem)
	r.GET("/items/:id", GetItem)
	r.GET("/items", ListItems)
	r.DELETE("/items/:id", DeleteItem)
}

func CreateItem(c *gin.Context)  {}
func GetItem(c *gin.Context)     {}
func ListItems(c *gin.Context)   {}
func DeleteItem(c *gin.Context)  {}
