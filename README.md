'Jetelina' is server-side middleware which is for managing your database and its Data Base Interface(DBI). Jetelina is an opensource program which is provided under MIT license. You can use Jetelina free and eidt it as far as keeping the license.

Jetelina can manage PostgreSQL, MySQL, redis and MongoDB so far, and you can use them at once. I mean, for example, PostgreSQL and redis run parallel on your server by managing Jetelina. All tables of each of databases are shown on Jeteina’s screen and can create DBI by selecting thier columns, i mean, you can create a SQL sentence ‘select name, address from yourtable’ sentence by selecting ‘name’ and ‘address’ columns from ‘yourtable’ table on Jetelina. This SQL sentence is to be able to accesse through JSON form. The insert/update/delete sentences are created automatically by Jetelina when you upload a CSV file that is the origin to be a table.

System requirements

-Julia = v12.6 (confirmed in Jetelina v4.0.0)
 
-RDBMS is mandatry: PostgreSQL or MySQL

　for managing users of Jeteilna and something else
 
-pg_ivm for PostgreSQL = v1.13 (comfirmed in Jetelina v3.1)

-Other DBs are options: redis, MongoDB

　depend on your usecase
 
-Linux(confirmed Ubuntu24) & Mac were comfirmed in Jetelina v3.1, Windows( should work, but not be comfirmed yet)

　no matter what os, as far as Julia works fine

**Parallel Release Announcement**

Powered by [Microsoft Multilingual E5 Text Embeddings: A Technical Report](https://arxiv.org)

We are now maintaining two parallel versions of this project to better serve our users. Both tracks are officially supported and available via the Releases section on the right sidebar.

Stable Track (main branch)
- Best for: Most users who need a production-ready, highly reliable version with minimal bugs.

AI Track (v4.0.0 branch)
- Best for: Early adopters who want to try out the latest features and cutting-edge improvements before they are officially finalized.

Note: We welcome feedback and bug reports for both versions. Please specify which version you are using when opening an issue.


**Docker version in v4.01***

## Deploying with Docker

Use the official pre-built Docker package to avoid local runtime setup. The AI model (approx. 145MB ONNX file) is pre-baked into the container image for a faster startup sequence.

### Quick Start Instructions

1. Clone the repository and navigate into the directory:
```bash
git clone -b v4.0.1 https://github.com/git-jetelina/Jetelina.git
cd Jetelina
```

2. Execute the startup script:
```bash
chmod +x run_jetelina_docker.sh
sudo ./run_jetelina_docker.sh start
```

3. Monitor container logs (First-time initialization takes approx. more a few minute):
```bash
sudo ./run_jetelina_docker.sh logs
```
*Note: Wait for the log output to display the server standby message before accessing the application.*

4. Access the Application at `http://localhost:8000/jetelina/` once ready.

---

### Upgrading from a Previous Version

To reset the container state and clear old configuration files from previous versions:

```bash
sudo ./run_jetelina_docker.sh stop
sudo docker volume rm jetelina_data
sudo ./run_jetelina_docker.sh start
```
