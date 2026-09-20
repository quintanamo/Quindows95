import { defineStore } from 'pinia'

export const useApplicationStore = defineStore('applications', {
  state: () => ({
    count: 0,
    activeIndex: 0,
    nextZIndex: 1,
    applications: [],
  }),
  getters: {
    getActiveIndex: state => state.activeIndex,
    getApplications: state => state.applications,
  },
  actions: {
    pushApplication(title, canResize = true) {
      this.count++
      this.applications.push({
        id: this.count,
        title: title,
        canResize: canResize,
        isMinimized: false,
        zIndex: this.nextZIndex++,
      })
      this.activeIndex = this.count
    },
    setActiveIndex(index) {
      this.activeIndex = index
      const application = this.applications.find(app => app.id === index)
      if (application) {
        application.isMinimized = false
        application.zIndex = this.nextZIndex++
      }
    },
    clearActiveIndex() {
      this.activeIndex = 0
    },
    minimizeApplication(id) {
      const application = this.applications.find(app => app.id === id)
      if (!application) return

      application.isMinimized = true
      if (this.activeIndex === id) this.activeIndex = 0
    },
    removeApplication(id) {
      this.applications = this.applications.filter(app => app.id !== id)
    },
  },
})
