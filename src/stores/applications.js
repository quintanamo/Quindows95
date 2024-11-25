import { ref } from 'vue'
import { defineStore } from 'pinia'

export const useApplicationStore = defineStore('applications', {
  state: () => ({ count: 0, activeIndex: 0, applications: [] }),
  getters: {
    getActiveIndex: state => state.activeIndex,
    getApplications: state => state.applications,
  },
  actions: {
    pushApplication(title) {
      this.count++
      this.applications.push({
        id: this.count,
        title: title,
        isMinimized: false,
      })
      this.activeIndex = this.count
    },
    setActiveIndex(index) {
      this.activeIndex = index
    },
  },
})
