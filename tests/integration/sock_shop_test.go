package sock_shop_test

import (
	"time"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/sclevine/agouti"
	. "github.com/sclevine/agouti/matchers"
)

var _ = Describe("SockShop", func() {
	var page *agouti.Page

	BeforeEach(func() {
		var err error
		page, err = agoutiDriver.NewPage(agouti.Browser("chrome"))
		Expect(err).NotTo(HaveOccurred())
	})

	AfterEach(func() {
		Expect(page.Destroy()).To(Succeed())
	})

	It("renders the front-end", func() {
		By("navigating to the homepage", func() {
			Expect(page.Navigate(sockShopURL)).To(Succeed())
		})

		By("finding the advantages section", func() {
			Eventually(find(page, "#advantages"), time.Second*10).Should(BeFound())
		})
	})
})

func find(page *agouti.Page, text string) func() *agouti.Selection {
	return func() *agouti.Selection {
		return page.Find(text)
	}
}
