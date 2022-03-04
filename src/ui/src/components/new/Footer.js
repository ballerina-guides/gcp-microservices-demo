import { useCookies } from 'react-cookie';

const CommentItem = (props) => {
    const [userIdCookie, setUserId] = useCookies(['userId']);
    const userId = userIdCookie.userId

    return (
        <footer className="py-5">
            <div className="footer-top">
                <div className="container footer-social">
                    <p className="footer-text">This website is hosted for demo purposes only. It is not an actual shop. This is not a Google product.</p>
                    <p className="footer-text">© 2020 Google Inc (<a href="https://github.com/GoogleCloudPlatform/microservices-demo">Source Code</a>)</p>
                    <p className="footer-text">
                        <small>
                            session-id: {userId}
                        </small>
                    </p>
                </div>
            </div>
        </footer>
    );
};

export default CommentItem;
