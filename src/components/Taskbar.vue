<script setup>
import { reactive, onMounted } from 'vue'
import { useApplicationStore } from '@/stores/applications'
import TaskbarButton from './TaskbarButton.vue'

const applications = useApplicationStore()

const data = reactive({
  time: '12:00 PM',
})

const getCurrentTime = () => {
  const time = new Date()
  const hours = time.getHours()
  const minutes = time.getMinutes()

  const suffix = hours > 12 ? 'PM' : 'AM'
  data.time = `${hours > 12 ? hours - 12 : hours}:${minutes < 10 ? '0' + minutes : minutes} ${suffix}`
}

onMounted(() => {
  getCurrentTime()
  setInterval(getCurrentTime, 1000 * 30)
})
</script>

<template>
  <footer class="taskbar">
    <button class="taskbar__start-btn">
      <img
        src="../assets/images/quindows-logo.png"
        alt="Quindows 95 Logo"
        class="taskbar__start-icon"
      />Start
    </button>
    <ul class="taskbar__container">
      <TaskbarButton
        v-for="application in applications.applications"
        :key="application.id"
        :id="application.id"
        :title="application.title"
      />
    </ul>
    <div class="taskbar__clock">{{ data.time }}</div>
  </footer>
</template>

<style lang="scss">
.taskbar {
  background-color: $color-gray;
  width: 100%;
  height: 4rem;
  border-top: 1px solid $color-white;
  box-sizing: border-box;
  padding-top: 0.3rem;
  padding-left: 0.4rem;
  padding-right: 0.4rem;
  padding-bottom: 0.2rem;
  display: flex;
  gap: 0.4rem 0.6rem;
  cursor: default;
  user-select: none;
  border-top: 0.1rem solid $color-white;
  z-index: 10000;

  &__start-btn {
    height: 3rem;
    box-sizing: border-box;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 0.4rem;
    font-size: 1.6rem;
    font-weight: bold;
    background-color: $color-gray;
    border-top: 1px solid $color-white;
    border-left: 1px solid $color-gray-dark;
    border-right: 1px solid $color-gray-dark;
    border-bottom: 1px solid $color-gray-dark;
    box-shadow: 1px 1px 0px #000000;
  }

  &__start-icon {
    height: 100%;
    margin-right: 1rem;
  }

  &__container {
    flex: 1;
    list-style: none;
    display: flex;
    gap: 0.4rem;
  }

  &__clock {
    width: 9rem;
    height: 3rem;
    border-top: 1px solid $color-gray-dark;
    border-left: 1px solid $color-gray-dark;
    border-right: 1px solid $color-white;
    border-bottom: 1px solid $color-white;
    text-align: center;
    font-size: 1.6rem;
    line-height: 3rem;
    vertical-align: middle;
  }
}
</style>
