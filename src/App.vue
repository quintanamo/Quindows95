<script setup>
import Desktop from './components/Desktop.vue'
import Taskbar from './components/Taskbar.vue'
</script>

<template>
  <Desktop />
  <Taskbar />
</template>

<style lang="scss">
.content {
  display: flex;
  flex-direction: column;
}
</style>
