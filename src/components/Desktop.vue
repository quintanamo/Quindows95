<script setup>
import DesktopIcon from './DesktopIcon.vue'
import InternetIcon from '../assets/images/internet.png'
import { useApplicationStore } from '@/stores/applications'
import ApplicationWindow from './ApplicationWindow.vue'
const applications = useApplicationStore()

const openApplication = (title, content, canResize = true) => {
  applications.pushApplication(title, content, canResize)
}

const handleDesktopClick = event => {
  if (event.target.closest('.application-window')) return
  applications.clearActiveIndex()
}
</script>

<template>
  <main class="desktop" v-on:click="handleDesktopClick">
    <template
      v-for="application in applications.applications"
      :key="application.id"
    >
      <ApplicationWindow
        v-show="!application.isMinimized"
        :id="application.id"
        :title="application.title"
        :can-resize="application.canResize"
        :content="application.content"
      />
    </template>
    <ul class="desktop__icons">
      <li>
        <DesktopIcon
          :icon-src="InternetIcon"
          title="My Site"
          @dblclick="
            openApplication('My Site', 'website:https://quintinherb.net')
          "
        />
      </li>
    </ul>
  </main>
</template>

<style lang="scss">
.desktop {
  flex: 1;
  position: relative;

  &__icons {
    display: flex;
    flex-direction: column;
    flex-wrap: wrap;
    list-style: none;
    height: 100%;
    align-content: start;
  }
}
</style>
