use crate::error::MddeError;
use reqwest::Client;
use tracing::info;

pub struct MddeClient {
    base_url: String,
    client: Client,
}

impl MddeClient {
    pub fn new(base_url: &str) -> Self {
        Self {
            base_url: base_url.to_string(),
            client: Client::new(),
        }
    }

    /// 获取基础URL
    pub fn get_base_url(&self) -> &str {
        &self.base_url
    }

    /// 下载指定目录的脚本
    pub async fn download_script(&self, directory: &str, filename: &str) -> Result<String, MddeError> {
        let url = format!("{}/{}/{}", self.base_url, directory, filename);
        info!("下载脚本: {}", url);
        println!("下载脚本-print: {}", url);

        let response = self.client.get(&url).send().await?;
        
        if response.status().is_success() {
            let content = response.text().await?;
            Ok(content)
        } else {
            Err(MddeError::HttpStatus(response.status().as_u16()))
        }
    }

    // /// 下载整个目录的脚本
    // pub async fn download_directory(&self, directory: &str) -> Result<Vec<u8>, MddeError> {
    //     let url = format!("{}/get/{}", self.base_url, directory);
    //     info!("下载目录: {}", url);

    //     let response = self.client.get(&url).send().await?;
        
    //     if response.status().is_success() {
    //         let content = response.bytes().await?;
    //         Ok(content.to_vec())
    //     } else {
    //         Err(MddeError::HttpStatus(response.status().as_u16()))
    //     }
    // }

    // /// 上传脚本到指定目录
    // pub async fn upload_script(
    //     &self,
    //     directory: &str,
    //     filename: &str,
    //     content: &[u8],
    // ) -> Result<(), MddeError> {
    //     let url = format!("{}/upload/{}", self.base_url, directory);
    //     info!("上传脚本: {} -> {}", filename, url);

    //     let form = reqwest::multipart::Form::new()
    //         .part("file", reqwest::multipart::Part::bytes(content.to_vec())
    //             .file_name(filename.to_string()));

    //     let response = self.client
    //         .post(&url)
    //         .multipart(form)
    //         .send()
    //         .await?;

    //     if response.status().is_success() {
    //         Ok(())
    //     } else {
    //         Err(MddeError::HttpStatus(response.status().as_u16()))
    //     }
    // }

    /// 获取脚本列表
    pub async fn list_scripts(&self, directory: Option<&str>) -> Result<serde_json::Value, MddeError> {
        let url = if let Some(dir) = directory {
            format!("{}/list/{}", self.base_url, dir)
        } else {
            format!("{}/list", self.base_url)
        };

        info!("获取脚本列表: {}", url);

        let response = self.client.get(&url).send().await?;
        
        if response.status().is_success() {
            let content = response.json().await?;
            Ok(content)
        } else {
            Err(MddeError::HttpStatus(response.status().as_u16()))
        }
    }

    /// 删除脚本
    pub async fn delete_script(&self, directory: &str, filename: &str) -> Result<(), MddeError> {
        let url = format!("{}/delete/{}/{}", self.base_url, directory, filename);
        info!("删除脚本: {}", url);

                let response = self.client.delete(&url).send().await?;

        if response.status().is_success() {
            Ok(())
        } else {
            Err(MddeError::HttpStatus(response.status().as_u16()))
        }
    }

    /// 检查服务器连接
    pub async fn ping(&self) -> Result<bool, MddeError> {
        let url = format!("{}/", self.base_url);
        
        match self.client.get(&url).send().await {
            Ok(response) => Ok(response.status().is_success()),
            Err(_) => Ok(false),
        }
    }
}
 