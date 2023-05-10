import { configureStore } from '@reduxjs/toolkit'
import appSlice from "./app_reducer.js";

export const store =  configureStore({
    reducer: {
        app: appSlice
    }
})