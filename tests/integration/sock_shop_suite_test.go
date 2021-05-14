package sock_shop_test

import (
	"os"
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/sclevine/agouti"
)

var sockShopURL string

func TestSockShop(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "SockShop Suite")
}

var agoutiDriver *agouti.WebDriver

var _ = BeforeSuite(func() {
	sockShopURL = os.Getenv("SOCK_SHOP_URL")
	Expect(sockShopURL).NotTo(BeEmpty())
	sockShopURL = "http://" + sockShopURL

	agoutiDriver = agouti.ChromeDriver(agouti.ChromeOptions("args", []string{
		"--headless",
		"--no-sandbox",
		"--disable-dev-shm-usage",
		"--disable-gpu",
		"--detach",
		"--whitelisted-ips",
	}), agouti.Debug)
	Expect(agoutiDriver.Start()).To(Succeed())
})

var _ = AfterSuite(func() {
	Expect(agoutiDriver.Stop()).To(Succeed())
})
